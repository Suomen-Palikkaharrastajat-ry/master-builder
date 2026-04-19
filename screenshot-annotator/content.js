/* Screenshot Annotator — content script */
"use strict";

// ── State ──────────────────────────────────────────────────────────────────

const state = {
  active: false,
  tool: "rect",
  color: "#F2705E", // rainbowSalmon
  strokeWidth: 3,
  annotations: [],   // { el, type }
  drawing: false,
  startX: 0,
  startY: 0,
  currentEl: null,
  calloutCounter: 1,
  lastCalloutSize: null, // remembers the most recently placed callout size
  // toolbar drag
  draggingToolbar: false,
  dragOffX: 0,
  dragOffY: 0,
  // last known mouse position (for Ctrl key hint refresh)
  mouseX: 0,
  mouseY: 0,
  // select / move / resize
  selected: null,      // annotation entry { el, type }
  selectMode: null,    // 'move' | 'resize'
  selectHandle: null,  // 'nw'|'ne'|'sw'|'se'|'start'|'end'|'e'
  selectDragX: 0,
  selectDragY: 0,
  origGeom: null,
  // screenshot capture area selection
  capturePhase: "idle", // 'idle'|'selecting'|'adjusting'|'capturing'
  captureDragging: false,
  captureDragMode: null, // 'new'|'move'|'resize'
  captureResizeHandle: null, // 'nw'|'ne'|'sw'|'se'
  captureStartX: 0,
  captureStartY: 0,
  captureOrigRect: null,
  captureRect: null,
  pendingCaptureRect: null,
};

// ── SVG helpers ────────────────────────────────────────────────────────────

const SVG_NS = "http://www.w3.org/2000/svg";

function svgEl(tag, attrs) {
  const el = document.createElementNS(SVG_NS, tag);
  for (const [k, v] of Object.entries(attrs)) el.setAttribute(k, v);
  return el;
}

// ── Snap-to-element ────────────────────────────────────────────────────────

const SNAP_THRESHOLD = 14;

function getSnapTarget(x, y) {
  const root = document.getElementById("annotator-root");
  const annSvg = document.getElementById("annotator-svg");
  const els = document.elementsFromPoint(x, y).filter(
    (el) => el !== root && !(root && root.contains(el)) &&
            el !== annSvg && !(annSvg && annSvg.contains(el)) &&
            el !== document.documentElement && el !== document.body
  );
  return els[0] || null;
}

// snapPoint takes viewport coords (clientX/Y) and returns page coords
function snapPoint(x, y) {
  const target = getSnapTarget(x, y);
  if (!target) return { x: x + window.scrollX, y: y + window.scrollY, snapped: false, rect: null };

  const r = target.getBoundingClientRect();
  let sx = x, sy = y;
  let snappedX = false, snappedY = false;

  if (Math.abs(x - r.left)   < SNAP_THRESHOLD) { sx = r.left;   snappedX = true; }
  if (Math.abs(x - r.right)  < SNAP_THRESHOLD) { sx = r.right;  snappedX = true; }
  if (Math.abs(y - r.top)    < SNAP_THRESHOLD) { sy = r.top;    snappedY = true; }
  if (Math.abs(y - r.bottom) < SNAP_THRESHOLD) { sy = r.bottom; snappedY = true; }

  const snapped = snappedX || snappedY;
  // Return page coordinates (viewport coords + scroll offset)
  return { x: sx + window.scrollX, y: sy + window.scrollY, snapped, rect: snapped ? r : null };
}

const CTRL_PAD = 6; // px padding added by Ctrl+Click
const CAPTURE_MIN_SIZE = 8;
const CAPTURE_ACTION_GAP = 8;
const CAPTURE_TILE_DELAY_MS = 80;
const TOAST_DEFAULT_MS = 2200;

function updateSnapHint(rect, ctrlMode = false) {
  const hint = document.getElementById("annotator-snap-hint");
  if (!hint) return;
  if (!rect) {
    hint.classList.remove("ann-visible", "ann-ctrl");
    return;
  }
  const pad = ctrlMode ? CTRL_PAD : 0;
  hint.style.left   = `${rect.left   - pad}px`;
  hint.style.top    = `${rect.top    - pad}px`;
  hint.style.width  = `${rect.width  + pad * 2}px`;
  hint.style.height = `${rect.height + pad * 2}px`;
  hint.classList.add("ann-visible");
  hint.classList.toggle("ann-ctrl", ctrlMode);
}

// ── Brick renderer ─────────────────────────────────────────────────────────
// Proportions derived from icons/brick.svg viewBox (6.4161444 x 4.5640707 mm)

const BRICK_W_RATIO = 6.4161444 / 4.5640707; // ~1.406  width : height


// Pick black or white text based on relative luminance of the fill color
function contrastText(hex) {
  const r = parseInt(hex.slice(1, 3), 16) / 255;
  const g = parseInt(hex.slice(3, 5), 16) / 255;
  const b = parseInt(hex.slice(5, 7), 16) / 255;
  const lin = (c) => c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  const L = 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
  return L > 0.179 ? "#05131D" : "#ffffff";
}

function renderCallout(g, cx, cy, size, fillColor, number) {
  while (g.firstChild) g.removeChild(g.firstChild);

  // Store geometry so getGeom / setGeom can read it without parsing children
  g.dataset.cx     = cx;
  g.dataset.cy     = cy;
  g.dataset.size   = size;
  g.dataset.color  = fillColor;
  g.dataset.number = number;

  if (size < 2) return; // invisible during initial zero-size draw

  const bw = size * BRICK_W_RATIO;
  const bh = size;
  const x0 = cx - bw / 2;
  const y0 = cy - bh / 2;

  // Normalised offsets from brick.svg (after applying the Inkscape translate)
  const bodyX = x0 + bw * 0.005;
  const bodyY = y0 + bh * 0.123;
  const bodyW = bw * 0.990;
  const bodyH = bh * 0.869;

  const studW    = bw * 0.289;
  const studH    = bh * 0.116;
  const stud1X   = x0 + bw * 0.108;
  const stud2X   = x0 + bw * 0.603;
  const topStudY = y0 + bh * 0.007;

  const border = "#05131D"; // legoBlack
  const sw     = Math.max(0.8, size * 0.025);

  // Body
  g.appendChild(svgEl("rect", {
    x: bodyX, y: bodyY, width: bodyW, height: bodyH,
    fill: fillColor, stroke: border, "stroke-width": sw,
  }));
  // Top studs
  for (const studX of [stud1X, stud2X]) {
    g.appendChild(svgEl("rect", {
      x: studX, y: topStudY, width: studW, height: studH,
      fill: fillColor, stroke: border, "stroke-width": sw,
    }));
  }
  // Number label centred on the body
  const num = svgEl("text", {
    x: cx, y: String(bodyY + bodyH / 2 + 1),
    "text-anchor": "middle", "dominant-baseline": "middle",
    fill: contrastText(fillColor),
    "font-size":   String(Math.max(10, bodyH * 0.65)),
    "font-weight": "bold",
    "font-family": "system-ui, sans-serif",
    "pointer-events": "none",
  });
  num.textContent = String(number);
  g.appendChild(num);
}

// ── Geometry helpers ───────────────────────────────────────────────────────
// Geom shapes:
//   rect / blur / text : { x, y, w, h }
//   circle             : { cx, cy, rx, ry }
//   arrow              : { x1, y1, x2, y2 }
//   callout            : { cx, cy, r }  (r = brick height)

function getGeom(type, el) {
  switch (type) {
    case "rect":
    case "blur":
    case "text":
      return {
        x: +el.getAttribute("x"),     y: +el.getAttribute("y"),
        w: +el.getAttribute("width"), h: +el.getAttribute("height"),
      };
    case "circle":
      return {
        cx: +el.getAttribute("cx"), cy: +el.getAttribute("cy"),
        rx: +el.getAttribute("rx"), ry: +el.getAttribute("ry"),
      };
    case "arrow":
      return {
        x1: +el.getAttribute("x1"), y1: +el.getAttribute("y1"),
        x2: +el.getAttribute("x2"), y2: +el.getAttribute("y2"),
      };
    case "callout":
      return { cx: +el.dataset.cx, cy: +el.dataset.cy, r: +el.dataset.size };
  }
}

function setGeom(type, el, g) {
  switch (type) {
    case "rect":
    case "blur":
    case "text":
      el.setAttribute("x", g.x);     el.setAttribute("y", g.y);
      el.setAttribute("width", g.w); el.setAttribute("height", g.h);
      break;
    case "circle":
      el.setAttribute("cx", g.cx); el.setAttribute("cy", g.cy);
      el.setAttribute("rx", g.rx); el.setAttribute("ry", g.ry);
      break;
    case "arrow":
      el.setAttribute("x1", g.x1); el.setAttribute("y1", g.y1);
      el.setAttribute("x2", g.x2); el.setAttribute("y2", g.y2);
      break;
    case "callout":
      renderCallout(el, g.cx, g.cy, g.r, el.dataset.color || state.color, el.dataset.number || "1");
      break;
  }
}

// Axis-aligned bounding box for any geom, used to draw the selection outline
function getBBox(type, g) {
  switch (type) {
    case "rect": case "blur": case "text":
      return { x: g.x, y: g.y, w: g.w, h: g.h };
    case "circle":
      return { x: g.cx - g.rx, y: g.cy - g.ry, w: g.rx * 2, h: g.ry * 2 };
    case "arrow":
      return { x: Math.min(g.x1, g.x2), y: Math.min(g.y1, g.y2),
               w: Math.abs(g.x2 - g.x1), h: Math.abs(g.y2 - g.y1) };
    case "callout":
      return { x: g.cx - (g.r * BRICK_W_RATIO) / 2, y: g.cy - g.r / 2,
               w: g.r * BRICK_W_RATIO,               h: g.r };
  }
}

function translateGeom(type, g, dx, dy) {
  switch (type) {
    case "rect": case "blur": case "text":
      return { ...g, x: g.x + dx, y: g.y + dy };
    case "circle":
      return { ...g, cx: g.cx + dx, cy: g.cy + dy };
    case "arrow":
      return { x1: g.x1 + dx, y1: g.y1 + dy, x2: g.x2 + dx, y2: g.y2 + dy };
    case "callout":
      return { ...g, cx: g.cx + dx, cy: g.cy + dy };
  }
}

function resizeGeom(type, g, handle, dx, dy) {
  switch (type) {
    case "rect": case "blur": case "text": {
      let { x, y, w, h } = g;
      if (handle.includes("n")) { y += dy; h -= dy; }
      if (handle.includes("s")) { h += dy; }
      if (handle.includes("w")) { x += dx; w -= dx; }
      if (handle.includes("e")) { w += dx; }
      if (w < 10) { if (handle.includes("w")) x += w - 10; w = 10; }
      if (h < 10) { if (handle.includes("n")) y += h - 10; h = 10; }
      return { x, y, w, h };
    }
    case "circle": {
      let left = g.cx - g.rx, top = g.cy - g.ry;
      let right = g.cx + g.rx, bottom = g.cy + g.ry;
      if (handle.includes("n")) top    += dy;
      if (handle.includes("s")) bottom += dy;
      if (handle.includes("w")) left   += dx;
      if (handle.includes("e")) right  += dx;
      const rx = Math.max(8, (right - left) / 2);
      const ry = Math.max(8, (bottom - top) / 2);
      return { cx: (left + right) / 2, cy: (top + bottom) / 2, rx, ry };
    }
    case "arrow": {
      if (handle === "start") return { ...g, x1: g.x1 + dx, y1: g.y1 + dy };
      if (handle === "end")   return { ...g, x2: g.x2 + dx, y2: g.y2 + dy };
      return g;
    }
    case "callout":
      // 'e' handle sits at cx + r * BRICK_W_RATIO/2; convert dx to delta-r
      return { ...g, r: Math.max(12, g.r + dx / (BRICK_W_RATIO / 2)) };
  }
}

// Handle specs: position and cursor for each resize handle of a given shape
function getHandleSpecs(type, geom) {
  if (type === "arrow") {
    return [
      { id: "start", cx: geom.x1, cy: geom.y1, cursor: "grab" },
      { id: "end",   cx: geom.x2, cy: geom.y2, cursor: "grab" },
    ];
  }
  if (type === "callout") {
    return [
      { id: "e", cx: geom.cx + (geom.r * BRICK_W_RATIO) / 2, cy: geom.cy, cursor: "ew-resize" },
    ];
  }
  const b = getBBox(type, geom);
  return [
    { id: "nw", cx: b.x,         cy: b.y,         cursor: "nw-resize" },
    { id: "ne", cx: b.x + b.w,   cy: b.y,         cursor: "ne-resize" },
    { id: "sw", cx: b.x,         cy: b.y + b.h,   cursor: "sw-resize" },
    { id: "se", cx: b.x + b.w,   cy: b.y + b.h,   cursor: "se-resize" },
  ];
}

// ── Selection overlay ──────────────────────────────────────────────────────

function selectAnnotation(entry) {
  state.selected = entry;
  showSelectionHandles(entry);
}

function deselectAnnotation() {
  state.selected = null;
  clearSelectionHandles();
}

function clearSelectionHandles() {
  const layer = document.getElementById("ann-select-layer");
  if (layer) while (layer.firstChild) layer.removeChild(layer.firstChild);
}

function showSelectionHandles(entry) {
  const layer = document.getElementById("ann-select-layer");
  if (!layer) return;
  clearSelectionHandles();

  const geom = getGeom(entry.type, entry.el);
  const bbox = getBBox(entry.type, geom);

  // Selection outline
  if (entry.type === "arrow") {
    layer.appendChild(svgEl("line", {
      x1: geom.x1, y1: geom.y1, x2: geom.x2, y2: geom.y2,
      stroke: "#3b82f6", "stroke-width": 1.5, "stroke-dasharray": "4 3",
      "pointer-events": "none",
    }));
  } else {
    layer.appendChild(svgEl("rect", {
      x: bbox.x - 4, y: bbox.y - 4, width: bbox.w + 8, height: bbox.h + 8,
      fill: "none", stroke: "#3b82f6", "stroke-width": 1.5,
      "stroke-dasharray": "4 3", rx: 3, "pointer-events": "none",
    }));
  }

  // Resize handles
  for (const spec of getHandleSpecs(entry.type, geom)) {
    const h = svgEl("rect", {
      x: spec.cx - 5, y: spec.cy - 5, width: 10, height: 10,
      class: "ann-handle",
    });
    h.style.cursor = spec.cursor;
    h.addEventListener("mousedown", (e) => {
      e.stopPropagation();
      e.preventDefault();
      beginAnnotationResize(e, spec.id);
    });
    layer.appendChild(h);
  }
}

// ── Annotation interactivity (called once per finalised annotation) ─────────

function makeSelectable(entry) {
  const el = entry.el;
  el.setAttribute("pointer-events", "all");
  el.addEventListener("mousedown", (e) => {
    if (state.tool !== "select") return;
    e.stopPropagation();
    e.preventDefault();
    selectAnnotation(entry);
    beginAnnotationMove(e);
  });
}

// ── Select-mode drag / resize ──────────────────────────────────────────────

function beginAnnotationMove(e) {
  state.selectMode = "move";
  state.selectDragX = e.pageX;
  state.selectDragY = e.pageY;
  state.origGeom = getGeom(state.selected.type, state.selected.el);
  document.addEventListener("mousemove", onSelectMouseMove);
  document.addEventListener("mouseup", onSelectMouseUp);
}

function beginAnnotationResize(e, handle) {
  state.selectMode = "resize";
  state.selectHandle = handle;
  state.selectDragX = e.pageX;
  state.selectDragY = e.pageY;
  state.origGeom = getGeom(state.selected.type, state.selected.el);
  document.addEventListener("mousemove", onSelectMouseMove);
  document.addEventListener("mouseup", onSelectMouseUp);
}

function onSelectMouseMove(e) {
  if (!state.selectMode || !state.selected) return;
  const dx = e.pageX - state.selectDragX;
  const dy = e.pageY - state.selectDragY;
  const newGeom = state.selectMode === "move"
    ? translateGeom(state.selected.type, state.origGeom, dx, dy)
    : resizeGeom(state.selected.type, state.origGeom, state.selectHandle, dx, dy);
  setGeom(state.selected.type, state.selected.el, newGeom);
  showSelectionHandles(state.selected);
}

function onSelectMouseUp() {
  state.selectMode = null;
  state.selectHandle = null;
  state.origGeom = null;
  document.removeEventListener("mousemove", onSelectMouseMove);
  document.removeEventListener("mouseup", onSelectMouseUp);
}

function deleteSelected() {
  if (!state.selected) return;
  const entry = state.selected;
  deselectAnnotation();
  entry.el.remove();
  const idx = state.annotations.indexOf(entry);
  if (idx >= 0) {
    state.annotations.splice(idx, 1);
    syncCalloutCounter();
    updateCaptureButtonTitle();
  }
}

// ── Build toolbar ──────────────────────────────────────────────────────────

const TOOLS = [
  { id: "select",  title: "Select / move / resize (S)" },
  { id: "rect",    title: "Rectangle (R)" },
  { id: "circle",  title: "Circle (C)" },
  { id: "arrow",   title: "Arrow (A)" },
  { id: "text",    title: "Text (T)" },
  { id: "callout", title: "Numbered callout (N)" },
  { id: "blur",    title: "Blur / redact (B)" },
];

// Colors from packages/design-tokens/src/DesignTokens/Colors.elm
const COLORS = [
  { hex: "#F2705E", label: "Salmon"            },
  { hex: "#F9BA61", label: "Light Orange"      },
  { hex: "#FAC80A", label: "Yellow"            },
  { hex: "#73DCA1", label: "Medium Green"      },
  { hex: "#9FC3E9", label: "Bright Light Blue" },
  { hex: "#9195CA", label: "Light Lilac"       },
  { hex: "#AC78BA", label: "Medium Lavender"   },
  { hex: "#FFFFFF", label: "White"             },
  { hex: "#05131D", label: "Black"             },
];

const WIDTHS = [
  { value: 2, height: "2px", title: "Thin" },
  { value: 4, height: "4px", title: "Medium" },
  { value: 8, height: "7px", title: "Thick" },
];

function createToolbarIcon(toolId) {
  const svg = svgEl("svg", { viewBox: "0 0 16 16" });

  switch (toolId) {
    case "select":
      svg.appendChild(svgEl("circle", { cx: "8", cy: "5", r: "3" }));
      svg.appendChild(svgEl("line", { x1: "8", y1: "8", x2: "8", y2: "16" }));
      svg.appendChild(svgEl("line", { x1: "5", y1: "13", x2: "8", y2: "16" }));
      svg.appendChild(svgEl("line", { x1: "11", y1: "13", x2: "8", y2: "16" }));
      break;
    case "rect":
      svg.appendChild(svgEl("rect", { x: "2", y: "4", width: "12", height: "9", rx: "1" }));
      break;
    case "circle":
      svg.appendChild(svgEl("ellipse", { cx: "8", cy: "8", rx: "6", ry: "5" }));
      break;
    case "arrow":
      svg.appendChild(svgEl("line", { x1: "2", y1: "13", x2: "13", y2: "3" }));
      svg.appendChild(svgEl("polyline", { points: "7,3 13,3 13,9" }));
      break;
    case "text":
      svg.appendChild(svgEl("line", { x1: "4", y1: "4", x2: "12", y2: "4" }));
      svg.appendChild(svgEl("line", { x1: "8", y1: "4", x2: "8", y2: "13" }));
      break;
    case "callout": {
      svg.appendChild(svgEl("circle", { cx: "8", cy: "8", r: "6" }));
      const t = svgEl("text", {
        x: "8", y: "12", "text-anchor": "middle",
        "font-size": "8", stroke: "none", fill: "currentColor", "font-weight": "bold",
      });
      t.textContent = "1";
      svg.appendChild(t);
      break;
    }
    case "blur":
      svg.appendChild(svgEl("rect", { x: "2", y: "4", width: "12", height: "9", rx: "1" }));
      svg.appendChild(svgEl("line", { x1: "2",  y1: "7",  x2: "14", y2: "7"  }));
      svg.appendChild(svgEl("line", { x1: "2",  y1: "10", x2: "14", y2: "10" }));
      svg.appendChild(svgEl("line", { x1: "5",  y1: "4",  x2: "5",  y2: "13" }));
      svg.appendChild(svgEl("line", { x1: "8",  y1: "4",  x2: "8",  y2: "13" }));
      svg.appendChild(svgEl("line", { x1: "11", y1: "4",  x2: "11", y2: "13" }));
      break;
  }

  return svg;
}

function createCaptureActionIcon(kind) {
  const svg = svgEl("svg", { viewBox: "0 0 16 16" });
  if (kind === "visible") {
    svg.appendChild(svgEl("rect", { x: "1.5", y: "3", width: "13", height: "10", rx: "1.8" }));
    svg.appendChild(svgEl("line", { x1: "4", y1: "3", x2: "4", y2: "13" }));
    svg.appendChild(svgEl("line", { x1: "12", y1: "3", x2: "12", y2: "13" }));
    svg.appendChild(svgEl("line", { x1: "4", y1: "8", x2: "12", y2: "8" }));
    return svg;
  }
  svg.appendChild(svgEl("rect", { x: "1.5", y: "1.5", width: "13", height: "13", rx: "1.8" }));
  svg.appendChild(svgEl("line", { x1: "5", y1: "1.5", x2: "5", y2: "14.5" }));
  svg.appendChild(svgEl("line", { x1: "9", y1: "1.5", x2: "9", y2: "14.5" }));
  svg.appendChild(svgEl("line", { x1: "1.5", y1: "5", x2: "14.5", y2: "5" }));
  svg.appendChild(svgEl("line", { x1: "1.5", y1: "9", x2: "14.5", y2: "9" }));
  return svg;
}

function getCalloutNumber(entry) {
  if (entry.type !== "callout") return null;
  const num = Number.parseInt(entry.el.querySelector("text")?.textContent || "", 10);
  return Number.isFinite(num) && num > 0 ? num : null;
}

function syncCalloutCounter() {
  let maxCallout = 0;
  for (const entry of state.annotations) {
    const value = getCalloutNumber(entry);
    if (value !== null && value > maxCallout) maxCallout = value;
  }
  state.calloutCounter = maxCallout + 1;
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function getTimestamp() {
  return new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
}

function getCaptureButtonTitle() {
  const action = state.annotations.length
    ? "Ctrl/Cmd+Click: save annotations JSON"
    : "Ctrl/Cmd+Click: load annotations JSON";
  return `Capture area screenshot (PNG). Shift+Click: full page. Alt+Click: visible area. ${action}`;
}

function updateCaptureButtonTitle() {
  const cap = document.getElementById("ann-capture");
  if (!cap) return;
  cap.title = getCaptureButtonTitle();
}

function showToast(message, kind = "info", timeoutMs = TOAST_DEFAULT_MS) {
  const toast = document.getElementById("ann-toast");
  if (!toast) return;
  const level = kind === "success" || kind === "error" ? kind : "info";
  toast.textContent = message;
  toast.className = `ann-toast ann-toast-${level} ann-visible`;
  if (showToast._timer) window.clearTimeout(showToast._timer);
  showToast._timer = window.setTimeout(() => {
    toast.classList.remove("ann-visible");
  }, timeoutMs);
}
showToast._timer = null;

function applySvgInteractionMode() {
  const svg = document.getElementById("annotator-svg");
  if (!svg) return;
  svg.classList.remove("ann-drawing", "ann-selecting", "ann-capture-selecting", "ann-capture-adjusting");
  if (state.capturePhase === "selecting") {
    svg.classList.add("ann-capture-selecting");
    return;
  }
  if (state.capturePhase === "adjusting") {
    svg.classList.add("ann-capture-adjusting");
    return;
  }
  if (state.capturePhase === "capturing") return;
  if (state.tool === "select") {
    svg.classList.add("ann-selecting");
  } else {
    svg.classList.add("ann-drawing");
  }
}

function buildToolbar() {
  const tb = document.createElement("div");
  tb.id = "annotator-toolbar";

  const drag = document.createElement("span");
  drag.className = "ann-drag";
  drag.title = "Drag to move toolbar";
  drag.textContent = "\u2823";
  tb.appendChild(drag);

  sep(tb);

  for (const t of TOOLS) {
    const btn = document.createElement("button");
    btn.className = "ann-btn" + (t.id === state.tool ? " ann-active" : "");
    btn.dataset.tool = t.id;
    btn.title = t.title;
    btn.appendChild(createToolbarIcon(t.id));
    tb.appendChild(btn);
  }

  sep(tb);

  const colDiv = document.createElement("div");
  colDiv.className = "ann-colors";
  for (const { hex, label } of COLORS) {
    const sw = document.createElement("span");
    sw.className = "ann-swatch" + (hex === state.color ? " ann-active" : "");
    sw.dataset.color = hex;
    sw.style.background = hex;
    sw.title = label;
    colDiv.appendChild(sw);
  }
  tb.appendChild(colDiv);

  sep(tb);

  const wDiv = document.createElement("div");
  wDiv.className = "ann-widths";
  for (const w of WIDTHS) {
    const btn = document.createElement("button");
    btn.className = "ann-width" + (w.value === state.strokeWidth ? " ann-active" : "");
    btn.dataset.width = w.value;
    btn.title = w.title;
    const swatch = document.createElement("span");
    swatch.style.height = w.height;
    btn.appendChild(swatch);
    wDiv.appendChild(btn);
  }
  tb.appendChild(wDiv);

  sep(tb);

  const undo = document.createElement("button");
  undo.className = "ann-btn";
  undo.id = "ann-undo";
  undo.title = "Undo (Ctrl+Z)";
  undo.innerHTML = '<svg viewBox="0 0 16 16"><path d="M3 7 C3 4 6 2 9 2 C12 2 14 4 14 7 C14 10 12 13 8 13"/><polyline points="3,4 3,7 6,7"/></svg>';
  tb.appendChild(undo);

  const clear = document.createElement("button");
  clear.className = "ann-btn ann-danger";
  clear.id = "ann-clear";
  clear.title = "Clear all annotations";
  clear.innerHTML = '<svg viewBox="0 0 16 16"><polyline points="3,4 13,4"/><rect x="5" y="4" width="6" height="9" rx="1"/><line x1="6.5" y1="4" x2="6" y2="2"/><line x1="9.5" y1="4" x2="10" y2="2"/></svg>';
  tb.appendChild(clear);

  sep(tb);

  const capVisible = document.createElement("button");
  capVisible.className = "ann-btn ann-capture ann-capture-alt";
  capVisible.id = "ann-capture-visible";
  capVisible.title = "Capture visible area (V / Ctrl+Shift+V)";
  capVisible.appendChild(createCaptureActionIcon("visible"));
  tb.appendChild(capVisible);

  const capFull = document.createElement("button");
  capFull.className = "ann-btn ann-capture ann-capture-alt";
  capFull.id = "ann-capture-fullpage";
  capFull.title = "Capture full page (F / Ctrl+Shift+F)";
  capFull.appendChild(createCaptureActionIcon("fullpage"));
  tb.appendChild(capFull);

  const cap = document.createElement("button");
  cap.className = "ann-btn ann-capture";
  cap.id = "ann-capture";
  cap.title = getCaptureButtonTitle();
  cap.innerHTML = '<svg viewBox="0 0 16 16"><rect x="1" y="4" width="14" height="10" rx="2"/><circle cx="8" cy="9" r="3"/><path d="M5 4 L6 2 L10 2 L11 4"/></svg>';
  tb.appendChild(cap);

  return tb;
}

function sep(parent) {
  const s = document.createElement("div");
  s.className = "ann-sep";
  parent.appendChild(s);
}

// ── SVG size (covers full document for scroll-relative annotations) ─────────

function updateSvgSize() {
  const svg = document.getElementById("annotator-svg");
  if (!svg) return;
  const w = Math.max(document.documentElement.scrollWidth,  window.innerWidth);
  const h = Math.max(document.documentElement.scrollHeight, window.innerHeight);
  svg.setAttribute("width",  w);
  svg.setAttribute("height", h);
  if (state.capturePhase !== "idle") {
    if (state.captureRect) {
      const maxX = Math.max(0, window.innerWidth - state.captureRect.w);
      const maxY = Math.max(0, window.innerHeight - state.captureRect.h);
      state.captureRect = {
        ...state.captureRect,
        x: clamp(state.captureRect.x, 0, maxX),
        y: clamp(state.captureRect.y, 0, maxY),
      };
    }
    renderCaptureSelection();
  }
}

// ── Inject / remove overlay ────────────────────────────────────────────────

function inject() {
  if (document.getElementById("annotator-root")) return;

  // Fixed overlay: toolbar + snap hint (stays in viewport)
  const root = document.createElement("div");
  root.id = "annotator-root";

  const snapHint = document.createElement("div");
  snapHint.id = "annotator-snap-hint";
  root.appendChild(snapHint);

  const captureHint = document.createElement("div");
  captureHint.id = "ann-capture-hint";
  captureHint.textContent = "Drag to select screenshot area. Esc to cancel.";
  root.appendChild(captureHint);

  const captureActions = document.createElement("div");
  captureActions.id = "ann-capture-actions";
  captureActions.innerHTML = `
    <button id="ann-capture-save" class="ann-capture-action ann-capture-save">Save</button>
    <button id="ann-capture-cancel" class="ann-capture-action ann-capture-cancel">Cancel</button>
  `;
  root.appendChild(captureActions);

  const toast = document.createElement("div");
  toast.id = "ann-toast";
  toast.className = "ann-toast";
  root.appendChild(toast);

  root.appendChild(buildToolbar());
  document.body.appendChild(root);

  // SVG is position:absolute so annotations scroll with the page
  const svg = document.createElementNS(SVG_NS, "svg");
  svg.id = "annotator-svg";
  svg.setAttribute("xmlns", SVG_NS);

  const defs = svgEl("defs", {});
  const marker = svgEl("marker", {
    id: "ann-arrow-head",
    markerWidth: "8", markerHeight: "8",
    refX: "6", refY: "3",
    orient: "auto", markerUnits: "strokeWidth",
  });
  marker.appendChild(svgEl("path", { d: "M0,0 L0,6 L8,3 z", fill: "context-stroke" }));
  defs.appendChild(marker);
  svg.appendChild(defs);

  // Screenshot capture area overlay
  svg.appendChild(svgEl("path", { id: "ann-capture-mask" }));
  svg.appendChild(svgEl("rect", { id: "ann-capture-box", x: 0, y: 0, width: 0, height: 0 }));
  svg.appendChild(svgEl("g", { id: "ann-capture-handles" }));

  // Selection overlay lives on top of all annotation elements
  svg.appendChild(svgEl("g", { id: "ann-select-layer" }));

  document.body.appendChild(svg);
  updateSvgSize();
  window.addEventListener("resize", updateSvgSize);

  bindEvents();
}

function teardown() {
  const root = document.getElementById("annotator-root");
  if (root) root.remove();
  const svg = document.getElementById("annotator-svg");
  if (svg) svg.remove();
  window.removeEventListener("resize", updateSvgSize);
  document.removeEventListener("keydown", onKeyDown);
  document.removeEventListener("keydown", onCtrlChange);
  document.removeEventListener("keyup", onCtrlChange);
  document.removeEventListener("mousemove", onIdleMouseMove);
  document.removeEventListener("mousemove", onSelectMouseMove);
  document.removeEventListener("mouseup", onSelectMouseUp);
  document.removeEventListener("mousemove", onDragMove);
  document.removeEventListener("mouseup", onDragEnd);
  state.active = false;
  state.annotations = [];
  state.calloutCounter = 1;
  state.lastCalloutSize = null;
  state.drawing = false;
  state.currentEl = null;
  state.selected = null;
  state.selectMode = null;
  state.capturePhase = "idle";
  state.captureDragging = false;
  state.captureDragMode = null;
  state.captureResizeHandle = null;
  state.captureOrigRect = null;
  state.captureRect = null;
  state.pendingCaptureRect = null;
}

// ── Event binding ──────────────────────────────────────────────────────────

function bindEvents() {
  const svg  = document.getElementById("annotator-svg");
  const tb   = document.getElementById("annotator-toolbar");
  const drag = tb.querySelector(".ann-drag");
  const actions = document.getElementById("ann-capture-actions");

  tb.addEventListener("click", onToolbarClick);
  drag.addEventListener("mousedown", onDragStart);
  actions.addEventListener("click", onCaptureActionsClick);

  svg.addEventListener("mousedown", onDrawStart);
  svg.addEventListener("mousemove", onDrawMove);
  svg.addEventListener("mouseup", onDrawEnd);

  document.addEventListener("mousemove", onIdleMouseMove, { passive: true });
  document.addEventListener("keydown", onKeyDown);
  document.addEventListener("keydown", onCtrlChange);
  document.addEventListener("keyup", onCtrlChange);
}

function onExtensionMessage(msg) {
  if (msg.type === "SHORTCUT_CAPTURE_VISIBLE") {
    void captureVisibleAreaScreenshot();
    return;
  }
  if (msg.type === "SHORTCUT_CAPTURE_FULLPAGE") {
    void captureFullPageScreenshot();
    return;
  }
  if (msg.type === "CAPTURED") {
    void handleCapturedImage(msg.dataUrl);
    return;
  }
  if (msg.type === "CAPTURE_ERROR") {
    console.error("[Annotator] Capture failed:", msg.error);
    showToast("Capture failed.", "error", 2600);
    state.pendingCaptureRect = null;
    restoreToolbarAfterCapture();
    cancelCaptureSelection();
  }
}

// ── Toolbar interactions ───────────────────────────────────────────────────

function onToolbarClick(e) {
  const btn      = e.target.closest("[data-tool]");
  if (btn)      return setTool(btn.dataset.tool);
  const swatch   = e.target.closest("[data-color]");
  if (swatch)   return setColor(swatch.dataset.color);
  const widthBtn = e.target.closest("[data-width]");
  if (widthBtn) return setWidth(Number(widthBtn.dataset.width));
  if (e.target.closest("#ann-undo"))    return undo();
  if (e.target.closest("#ann-clear"))   return clearAll();
  if (e.target.closest("#ann-capture-visible")) return void captureVisibleAreaScreenshot();
  if (e.target.closest("#ann-capture-fullpage")) return void captureFullPageScreenshot();
  if (e.target.closest("#ann-capture")) return onCaptureClick(e);
}

function onCaptureClick(e) {
  if (e.ctrlKey || e.metaKey) {
    if (state.annotations.length > 0) {
      void exportAnnotationsJson();
    } else {
      importAnnotationsJson();
    }
    return;
  }
  if (e.shiftKey) {
    void captureFullPageScreenshot();
    return;
  }
  if (e.altKey) {
    void captureVisibleAreaScreenshot();
    return;
  }
  beginCaptureSelection();
}

function onCaptureActionsClick(e) {
  if (e.target.closest("#ann-capture-save")) {
    e.preventDefault();
    e.stopPropagation();
    void confirmCaptureSelection();
    return;
  }
  if (e.target.closest("#ann-capture-cancel")) {
    e.preventDefault();
    e.stopPropagation();
    cancelCaptureSelection();
  }
}

function setTool(id) {
  if (state.capturePhase !== "idle") cancelCaptureSelection();
  state.tool = id;
  document.querySelectorAll(".ann-btn[data-tool]").forEach(
    (b) => b.classList.toggle("ann-active", b.dataset.tool === id)
  );
  applySvgInteractionMode();
  if (id !== "select") deselectAnnotation();
  saveSettings();
}

function setColor(c) {
  state.color = c;
  document.querySelectorAll(".ann-swatch").forEach(
    (sw) => sw.classList.toggle("ann-active", sw.dataset.color === c)
  );
  saveSettings();
}

function setWidth(w) {
  state.strokeWidth = w;
  document.querySelectorAll(".ann-width").forEach(
    (b) => b.classList.toggle("ann-active", Number(b.dataset.width) === w)
  );
  saveSettings();
}

// ── Toolbar drag ───────────────────────────────────────────────────────────

function onDragStart(e) {
  e.preventDefault();
  const rect = document.getElementById("annotator-toolbar").getBoundingClientRect();
  state.draggingToolbar = true;
  state.dragOffX = e.clientX - rect.left;
  state.dragOffY = e.clientY - rect.top;
  document.addEventListener("mousemove", onDragMove);
  document.addEventListener("mouseup", onDragEnd);
}

function onDragMove(e) {
  if (!state.draggingToolbar) return;
  const tb = document.getElementById("annotator-toolbar");
  tb.style.left      = `${e.clientX - state.dragOffX}px`;
  tb.style.top       = `${e.clientY - state.dragOffY}px`;
  tb.style.transform = "none";
}

function onDragEnd() {
  state.draggingToolbar = false;
  document.removeEventListener("mousemove", onDragMove);
  document.removeEventListener("mouseup", onDragEnd);
}

// ── Snap hint on idle move ─────────────────────────────────────────────────

function onIdleMouseMove(e) {
  state.mouseX = e.clientX;
  state.mouseY = e.clientY;
  refreshSnapHint(e.clientX, e.clientY, e.ctrlKey);
}

function refreshSnapHint(x, y, ctrlKey) {
  if (state.capturePhase !== "idle" || state.drawing || state.tool === "select" ||
      state.tool === "text" || state.tool === "blur") {
    updateSnapHint(null);
    return;
  }
  if (ctrlKey && state.tool !== "arrow") {
    const target = getSnapTarget(x, y);
    updateSnapHint(target ? target.getBoundingClientRect() : null, true);
    return;
  }
  const { snapped, rect } = snapPoint(x, y);
  updateSnapHint(snapped ? rect : null);
}

function onCtrlChange(e) {
  if (e.key !== "Control") return;
  refreshSnapHint(state.mouseX, state.mouseY, e.type === "keydown");
}

// ── Ctrl+Click: stamp annotation around hovered element ───────────────────

function ctrlClickAnnotate(x, y) {
  const target = getSnapTarget(x, y);
  if (!target) return false;

  const r   = target.getBoundingClientRect();
  const pad = CTRL_PAD;
  const ox  = window.scrollX;
  const oy  = window.scrollY;
  const c   = state.color;
  const sw  = state.strokeWidth;
  let el;
  let newCalloutSize = null;

  switch (state.tool) {
    case "rect":
      el = svgEl("rect", {
        x: r.left + ox - pad, y: r.top + oy - pad,
        width: r.width + pad * 2, height: r.height + pad * 2,
        fill: "none", stroke: c, "stroke-width": sw, rx: 2,
      });
      break;

    case "circle":
      el = svgEl("ellipse", {
        cx: r.left + ox + r.width / 2, cy: r.top + oy + r.height / 2,
        rx: r.width  / 2 + pad,        ry: r.height / 2 + pad,
        fill: "none", stroke: c, "stroke-width": sw,
      });
      break;

    case "blur": {
      el = document.createElementNS(SVG_NS, "foreignObject");
      el.setAttribute("x", r.left + ox - pad);
      el.setAttribute("y", r.top  + oy - pad);
      el.setAttribute("width",  r.width  + pad * 2);
      el.setAttribute("height", r.height + pad * 2);
      const inner = document.createElement("div");
      inner.style.cssText =
        "width:100%;height:100%;backdrop-filter:blur(8px);" +
        "-webkit-backdrop-filter:blur(8px);background:rgba(0,0,0,0.15);";
      el.appendChild(inner);
      break;
    }

    case "callout": {
      el = document.createElementNS(SVG_NS, "g");
      // Use last callout size if set, otherwise derive from element size
      newCalloutSize = state.lastCalloutSize || Math.max(24, Math.min(r.width, r.height) / 3 + pad);
      // Top-left quadrant, then golden cut (38.2%) within it, vertically centred in quadrant
      const cx = r.left + ox + (r.width  / 2) * 0.382;
      const cy = r.top  + oy + (r.height / 2) / 2;
      renderCallout(el, cx, cy, newCalloutSize, c, state.calloutCounter);
      break;
    }

    case "text": {
      el = document.createElementNS(SVG_NS, "foreignObject");
      el.setAttribute("x", r.left + ox - pad);
      el.setAttribute("y", r.top  + oy - pad);
      el.setAttribute("width",  "200");
      el.setAttribute("height", "40");
      el.classList.add("ann-text-fo");
      const div = document.createElement("div");
      div.className = "ann-text-input";
      div.contentEditable = "true";
      div.style.color = c;
      div.style.fontSize = `${14 + sw * 2}px`;
      div.textContent = window.getSelection().toString().trim();
      el.appendChild(div);
      break;
    }

    default:
      return false; // arrow doesn't snap-wrap
  }

  const layer = document.getElementById("ann-select-layer");
  document.getElementById("annotator-svg").insertBefore(el, layer);

  const entry = { el, type: state.tool };
  state.annotations.push(entry);
  makeSelectable(entry);
  if (state.tool === "callout") {
    if (newCalloutSize !== null) state.lastCalloutSize = newCalloutSize;
    state.calloutCounter++;
  }
  if (state.tool === "text") {
    const fo = el.querySelector(".ann-text-input");
    if (fo) fo.focus();
  }

  updateSnapHint(null);
  updateCaptureButtonTitle();
  return true;
}

// ── Screenshot area selection ───────────────────────────────────────────────

function setCaptureBox(rect) {
  const box = document.getElementById("ann-capture-box");
  if (!box) return;
  if (!rect) {
    box.classList.remove("ann-visible");
    box.setAttribute("x", "0");
    box.setAttribute("y", "0");
    box.setAttribute("width", "0");
    box.setAttribute("height", "0");
    return;
  }
  // SVG is position:absolute, so convert viewport coords to page coords
  box.setAttribute("x", String(rect.x + window.scrollX));
  box.setAttribute("y", String(rect.y + window.scrollY));
  box.setAttribute("width",  String(rect.w));
  box.setAttribute("height", String(rect.h));
  box.classList.add("ann-visible");
}

function setCaptureMask(rect) {
  const mask = document.getElementById("ann-capture-mask");
  if (!mask) return;
  if (!rect) {
    mask.classList.remove("ann-visible");
    mask.setAttribute("d", "");
    return;
  }
  const pageW = Math.max(document.documentElement.scrollWidth, window.innerWidth);
  const pageH = Math.max(document.documentElement.scrollHeight, window.innerHeight);
  const left = rect.x + window.scrollX;
  const top = rect.y + window.scrollY;
  const right = left + rect.w;
  const bottom = top + rect.h;
  mask.setAttribute(
    "d",
    `M0 0 H${pageW} V${pageH} H0 Z M${left} ${top} H${right} V${bottom} H${left} Z`
  );
  mask.classList.add("ann-visible");
}

function setCaptureHandles(rect) {
  const layer = document.getElementById("ann-capture-handles");
  if (!layer) return;
  while (layer.firstChild) layer.removeChild(layer.firstChild);
  if (!rect || state.capturePhase !== "adjusting") return;

  const ox = window.scrollX;
  const oy = window.scrollY;
  const specs = [
    { id: "nw", x: rect.x + ox, y: rect.y + oy, cursor: "nwse-resize" },
    { id: "ne", x: rect.x + rect.w + ox, y: rect.y + oy, cursor: "nesw-resize" },
    { id: "sw", x: rect.x + ox, y: rect.y + rect.h + oy, cursor: "nesw-resize" },
    { id: "se", x: rect.x + rect.w + ox, y: rect.y + rect.h + oy, cursor: "nwse-resize" },
  ];
  for (const spec of specs) {
    const handle = svgEl("rect", {
      x: spec.x - 6,
      y: spec.y - 6,
      width: 12,
      height: 12,
      class: "ann-capture-handle",
      "data-capture-handle": spec.id,
    });
    handle.style.cursor = spec.cursor;
    layer.appendChild(handle);
  }
}

function setCaptureHintVisible(visible) {
  const hint = document.getElementById("ann-capture-hint");
  if (!hint) return;
  hint.classList.toggle("ann-visible", visible);
}

function setCaptureActionsVisible(visible) {
  const actions = document.getElementById("ann-capture-actions");
  if (!actions) return;
  actions.classList.toggle("ann-visible", visible);
}

function positionCaptureActions(rect) {
  const actions = document.getElementById("ann-capture-actions");
  if (!actions || !rect) return;
  const actionsRect = actions.getBoundingClientRect();
  const vw = window.innerWidth;
  const vh = window.innerHeight;
  const x = clamp(
    rect.x + rect.w - actionsRect.width,
    CAPTURE_ACTION_GAP,
    vw - actionsRect.width - CAPTURE_ACTION_GAP
  );
  const placeAbove = rect.y - actionsRect.height - CAPTURE_ACTION_GAP >= CAPTURE_ACTION_GAP;
  const y = placeAbove
    ? rect.y - actionsRect.height - CAPTURE_ACTION_GAP
    : clamp(rect.y + rect.h + CAPTURE_ACTION_GAP, CAPTURE_ACTION_GAP, vh - actionsRect.height - CAPTURE_ACTION_GAP);
  actions.style.left = `${Math.round(x)}px`;
  actions.style.top = `${Math.round(y)}px`;
}

function renderCaptureSelection() {
  const rect = state.captureRect;
  setCaptureBox(rect);
  setCaptureMask(rect);
  setCaptureHandles(rect);
  const showActions = state.capturePhase === "adjusting" && !!rect;
  setCaptureActionsVisible(showActions);
  if (showActions) positionCaptureActions(rect);
}

function getNormalizedRect(x1, y1, x2, y2) {
  const left   = Math.min(x1, x2);
  const right  = Math.max(x1, x2);
  const top    = Math.min(y1, y2);
  const bottom = Math.max(y1, y2);
  return {
    x: clamp(left,  0, window.innerWidth),
    y: clamp(top,   0, window.innerHeight),
    w: Math.max(0, clamp(right,  0, window.innerWidth)  - clamp(left, 0, window.innerWidth)),
    h: Math.max(0, clamp(bottom, 0, window.innerHeight) - clamp(top,  0, window.innerHeight)),
  };
}

function isCaptureRectValid(rect) {
  return Boolean(rect && rect.w >= CAPTURE_MIN_SIZE && rect.h >= CAPTURE_MIN_SIZE);
}

function isPointInRect(x, y, rect) {
  if (!rect) return false;
  return x >= rect.x && x <= rect.x + rect.w && y >= rect.y && y <= rect.y + rect.h;
}

function moveCaptureRect(origRect, dx, dy) {
  const maxX = Math.max(0, window.innerWidth - origRect.w);
  const maxY = Math.max(0, window.innerHeight - origRect.h);
  return {
    x: clamp(origRect.x + dx, 0, maxX),
    y: clamp(origRect.y + dy, 0, maxY),
    w: origRect.w,
    h: origRect.h,
  };
}

function resizeCaptureRect(origRect, handle, dx, dy) {
  let left = origRect.x;
  let right = origRect.x + origRect.w;
  let top = origRect.y;
  let bottom = origRect.y + origRect.h;

  if (handle.includes("w")) left = clamp(left + dx, 0, right - CAPTURE_MIN_SIZE);
  if (handle.includes("e")) right = clamp(right + dx, left + CAPTURE_MIN_SIZE, window.innerWidth);
  if (handle.includes("n")) top = clamp(top + dy, 0, bottom - CAPTURE_MIN_SIZE);
  if (handle.includes("s")) bottom = clamp(bottom + dy, top + CAPTURE_MIN_SIZE, window.innerHeight);

  return { x: left, y: top, w: right - left, h: bottom - top };
}

function isCaptureInteractionActive() {
  return state.capturePhase === "selecting" || state.capturePhase === "adjusting";
}

function getCaptureHandleFromTarget(target) {
  if (!(target instanceof Element)) return null;
  const handle = target.closest("[data-capture-handle]");
  if (!handle) return null;
  return handle.getAttribute("data-capture-handle");
}

function beginCaptureSelection() {
  state.capturePhase = "selecting";
  state.captureDragging = false;
  state.captureDragMode = null;
  state.captureResizeHandle = null;
  state.captureOrigRect = null;
  state.captureRect = null;
  updateSnapHint(null);
  deselectAnnotation();
  applySvgInteractionMode();
  setCaptureHintVisible(true);
  renderCaptureSelection();
  showToast("Drag to select an area, then click Save.", "info", 2400);
}

function enterCaptureAdjusting(rect) {
  state.capturePhase = "adjusting";
  state.captureDragging = false;
  state.captureDragMode = null;
  state.captureResizeHandle = null;
  state.captureOrigRect = null;
  state.captureRect = rect;
  setCaptureHintVisible(false);
  applySvgInteractionMode();
  renderCaptureSelection();
  showToast("Selection ready. Move/resize it, then click Save.", "info", 2400);
}

function cancelCaptureSelection() {
  state.capturePhase = "idle";
  state.captureDragging = false;
  state.captureDragMode = null;
  state.captureResizeHandle = null;
  state.captureOrigRect = null;
  state.captureRect = null;
  const svg = document.getElementById("annotator-svg");
  if (svg) svg.classList.remove("ann-capture-ui-hidden");
  setCaptureHintVisible(false);
  renderCaptureSelection();
  applySvgInteractionMode();
}

function restoreToolbarAfterCapture() {
  const root = document.getElementById("annotator-root");
  if (root) root.classList.remove("ann-capture-ui-hidden");
  const tb = document.getElementById("annotator-toolbar");
  if (tb) {
    tb.style.opacity = "";
    tb.style.visibility = "";
  }
  const svg = document.getElementById("annotator-svg");
  if (svg) svg.classList.remove("ann-capture-ui-hidden");
}

function prepareUiForCapture() {
  const root = document.getElementById("annotator-root");
  if (root) root.classList.add("ann-capture-ui-hidden");
  const tb = document.getElementById("annotator-toolbar");
  if (tb) {
    tb.style.opacity = "0";
    tb.style.visibility = "hidden";
  }
  const svg = document.getElementById("annotator-svg");
  if (svg) svg.classList.add("ann-capture-ui-hidden");
  updateSnapHint(null);
  setCaptureHintVisible(false);
  setCaptureActionsVisible(false);
}

function delay(ms) {
  return new Promise((resolve) => window.setTimeout(resolve, ms));
}

async function captureVisibleDataUrl() {
  return browser.runtime.sendMessage({ type: "CAPTURE" });
}

function getCaptureScrollStops(total, viewport) {
  if (total <= viewport) return [0];
  const stops = [];
  for (let pos = 0; pos < total; pos += viewport) stops.push(pos);
  const last = Math.max(0, total - viewport);
  if (stops[stops.length - 1] !== last) stops.push(last);
  return stops;
}

async function captureFullPageDataUrl() {
  const root = document.documentElement;
  const body = document.body;
  const pageW = Math.max(root.scrollWidth, body ? body.scrollWidth : 0, window.innerWidth);
  const pageH = Math.max(root.scrollHeight, body ? body.scrollHeight : 0, window.innerHeight);
  const viewportW = Math.max(1, window.innerWidth);
  const viewportH = Math.max(1, window.innerHeight);
  const xStops = getCaptureScrollStops(pageW, viewportW);
  const yStops = getCaptureScrollStops(pageH, viewportH);
  const originalX = window.scrollX;
  const originalY = window.scrollY;
  const previousScrollBehavior = root.style.scrollBehavior;
  root.style.scrollBehavior = "auto";

  let canvas = null;
  let ctx = null;
  let scaleX = 1;
  let scaleY = 1;

  try {
    for (const y of yStops) {
      for (const x of xStops) {
        window.scrollTo(x, y);
        await waitForPaint();
        await delay(CAPTURE_TILE_DELAY_MS);

        const tileDataUrl = await captureVisibleDataUrl();
        const tileImg = await loadImageFromDataUrl(tileDataUrl);

        if (!canvas) {
          scaleX = tileImg.naturalWidth / viewportW;
          scaleY = tileImg.naturalHeight / viewportH;
          canvas = document.createElement("canvas");
          canvas.width = Math.max(1, Math.round(pageW * scaleX));
          canvas.height = Math.max(1, Math.round(pageH * scaleY));
          ctx = canvas.getContext("2d");
          if (!ctx) throw new Error("Could not prepare full-page canvas");
        }

        const dx = Math.round(x * scaleX);
        const dy = Math.round(y * scaleY);
        const remainingW = canvas.width - dx;
        const remainingH = canvas.height - dy;
        const srcW = Math.min(tileImg.naturalWidth, remainingW);
        const srcH = Math.min(tileImg.naturalHeight, remainingH);
        if (srcW <= 0 || srcH <= 0) continue;
        ctx.drawImage(tileImg, 0, 0, srcW, srcH, dx, dy, srcW, srcH);
      }
    }

    if (!canvas) throw new Error("Could not capture full page");
    return canvas.toDataURL("image/png");
  } finally {
    root.style.scrollBehavior = previousScrollBehavior;
    window.scrollTo(originalX, originalY);
    await waitForPaint();
  }
}

async function captureVisibleAreaScreenshot() {
  if (state.capturePhase === "capturing") return;
  const prevPhase = state.capturePhase;
  state.capturePhase = "capturing";
  applySvgInteractionMode();
  prepareUiForCapture();

  try {
    await waitForPaint();
    const dataUrl = await captureVisibleDataUrl();
    const saved = await saveDataUrlWithDialog(dataUrl, `screenshot-visible-${getTimestamp()}.png`);
    showToast(saved ? "Visible-area screenshot saved." : "Save canceled.");
  } catch (err) {
    console.error("[Annotator] Could not capture visible area:", err);
    showToast("Visible-area capture failed.", "error", 2800);
  } finally {
    restoreToolbarAfterCapture();
    state.capturePhase = prevPhase === "capturing" ? "idle" : prevPhase;
    if (state.capturePhase !== "idle") state.capturePhase = "idle";
    applySvgInteractionMode();
  }
}

async function captureFullPageScreenshot() {
  if (state.capturePhase === "capturing") return;
  const prevPhase = state.capturePhase;
  state.capturePhase = "capturing";
  applySvgInteractionMode();
  prepareUiForCapture();

  try {
    await waitForPaint();
    const dataUrl = await captureFullPageDataUrl();
    const saved = await saveDataUrlWithDialog(dataUrl, `screenshot-fullpage-${getTimestamp()}.png`);
    showToast(saved ? "Full-page screenshot saved." : "Save canceled.");
  } catch (err) {
    console.error("[Annotator] Could not capture full page:", err);
    showToast("Full-page capture failed.", "error", 2800);
  } finally {
    restoreToolbarAfterCapture();
    state.capturePhase = prevPhase === "capturing" ? "idle" : prevPhase;
    if (state.capturePhase !== "idle") state.capturePhase = "idle";
    applySvgInteractionMode();
  }
}

function beginCaptureDrag(mode, startX, startY, handle = null) {
  state.captureDragging = true;
  state.captureDragMode = mode;
  state.captureResizeHandle = handle;
  state.captureStartX = startX;
  state.captureStartY = startY;
  state.captureOrigRect = state.captureRect ? { ...state.captureRect } : null;
}

function updateCaptureDrag(clientX, clientY) {
  if (!state.captureDragging) return;
  if (state.captureDragMode === "new") {
    state.captureRect = getNormalizedRect(state.captureStartX, state.captureStartY, clientX, clientY);
  } else if (state.captureDragMode === "move" && state.captureOrigRect) {
    state.captureRect = moveCaptureRect(state.captureOrigRect, clientX - state.captureStartX, clientY - state.captureStartY);
  } else if (state.captureDragMode === "resize" && state.captureOrigRect && state.captureResizeHandle) {
    state.captureRect = resizeCaptureRect(
      state.captureOrigRect,
      state.captureResizeHandle,
      clientX - state.captureStartX,
      clientY - state.captureStartY
    );
  }
  renderCaptureSelection();
}

function endCaptureDrag(clientX, clientY) {
  if (!state.captureDragging) return;
  updateCaptureDrag(clientX, clientY);
  const finishedMode = state.captureDragMode;
  const rect = state.captureRect;
  state.captureDragging = false;
  state.captureDragMode = null;
  state.captureResizeHandle = null;
  state.captureOrigRect = null;

  if (finishedMode === "new") {
    if (!isCaptureRectValid(rect)) {
      cancelCaptureSelection();
      showToast("Selection too small. Drag a larger area.", "info", 2200);
      return;
    }
    enterCaptureAdjusting(rect);
    return;
  }

  if (!isCaptureRectValid(rect)) {
    cancelCaptureSelection();
    showToast("Selection became too small.", "info", 2200);
    return;
  }
  renderCaptureSelection();
}

function waitForPaint() {
  return new Promise((resolve) => {
    requestAnimationFrame(() => requestAnimationFrame(resolve));
  });
}

async function requestCapture(rect) {
  state.pendingCaptureRect = { ...rect };
  state.capturePhase = "capturing";
  state.captureDragging = false;
  state.captureDragMode = null;
  state.captureResizeHandle = null;
  state.captureOrigRect = null;
  setCaptureHintVisible(false);
  setCaptureActionsVisible(false);
  setCaptureHandles(null);
  setCaptureMask(null);
  setCaptureBox(null);
  applySvgInteractionMode();
  prepareUiForCapture();

  await waitForPaint();
  try {
    const dataUrl = await captureVisibleDataUrl();
    await handleCapturedImage(dataUrl);
  } catch (err) {
    console.error("[Annotator] Failed to request capture:", err);
    showToast("Capture failed.", "error", 2600);
    restoreToolbarAfterCapture();
    cancelCaptureSelection();
    state.pendingCaptureRect = null;
  }
}

async function confirmCaptureSelection() {
  if (state.capturePhase !== "adjusting" || !isCaptureRectValid(state.captureRect)) {
    cancelCaptureSelection();
    return;
  }
  await requestCapture(state.captureRect);
}

function loadImageFromDataUrl(dataUrl) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error("Could not load captured image"));
    img.src = dataUrl;
  });
}

async function cropDataUrl(dataUrl, rect) {
  const img = await loadImageFromDataUrl(dataUrl);
  const viewportW = Math.max(1, window.innerWidth);
  const viewportH = Math.max(1, window.innerHeight);
  const scaleX = img.naturalWidth / viewportW;
  const scaleY = img.naturalHeight / viewportH;
  const sx = clamp(Math.floor(rect.x * scaleX), 0, img.naturalWidth - 1);
  const sy = clamp(Math.floor(rect.y * scaleY), 0, img.naturalHeight - 1);
  const maxW = img.naturalWidth - sx;
  const maxH = img.naturalHeight - sy;
  const sw = Math.max(1, Math.min(maxW, Math.round(rect.w * scaleX)));
  const sh = Math.max(1, Math.min(maxH, Math.round(rect.h * scaleY)));

  const canvas = document.createElement("canvas");
  canvas.width = sw;
  canvas.height = sh;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Could not prepare canvas context for cropping");
  ctx.drawImage(img, sx, sy, sw, sh, 0, 0, sw, sh);
  return canvas.toDataURL("image/png");
}

function isCancelledSaveError(err) {
  const msg = String(err?.message || err || "").toLowerCase();
  return msg.includes("canceled") || msg.includes("cancelled");
}

async function saveDataUrlWithDialog(dataUrl, filename) {
  try {
    await browser.runtime.sendMessage({
      type: "SAVE_FILE",
      dataUrl,
      filename,
      saveAs: true,
    });
    return true;
  } catch (err) {
    if (isCancelledSaveError(err)) return false;
    throw err;
  }
}

async function blobToDataUrl(blob) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result || ""));
    reader.onerror = () => reject(reader.error || new Error("Could not read blob"));
    reader.readAsDataURL(blob);
  });
}

async function handleCapturedImage(dataUrl) {
  const rect = state.pendingCaptureRect;
  try {
    let output = dataUrl;
    if (isCaptureRectValid(rect)) {
      output = await cropDataUrl(dataUrl, rect);
    }
    const saved = await saveDataUrlWithDialog(output, `screenshot-${getTimestamp()}.png`);
    showToast(saved ? "Screenshot saved." : "Save canceled.");
  } catch (err) {
    console.error("[Annotator] Could not save screenshot:", err);
    showToast("Could not save screenshot.", "error", 2800);
  } finally {
    state.pendingCaptureRect = null;
    restoreToolbarAfterCapture();
    cancelCaptureSelection();
  }
}

// ── Drawing ────────────────────────────────────────────────────────────────

function onDrawStart(e) {
  if (e.button !== 0) return;
  // If a text annotation is focused, clicking elsewhere just blurs it
  if (document.activeElement && document.activeElement.classList.contains("ann-text-input")) {
    document.activeElement.blur();
    return;
  }
  if (isCaptureInteractionActive()) {
    e.preventDefault();
    e.stopPropagation();
    const handle = state.capturePhase === "adjusting" ? getCaptureHandleFromTarget(e.target) : null;
    if (state.capturePhase === "adjusting" && handle && state.captureRect) {
      beginCaptureDrag("resize", e.clientX, e.clientY, handle);
      return;
    }
    if (state.capturePhase === "adjusting" && isPointInRect(e.clientX, e.clientY, state.captureRect)) {
      beginCaptureDrag("move", e.clientX, e.clientY);
      return;
    }
    state.capturePhase = "selecting";
    state.captureRect = getNormalizedRect(e.clientX, e.clientY, e.clientX, e.clientY);
    setCaptureHintVisible(true);
    applySvgInteractionMode();
    beginCaptureDrag("new", e.clientX, e.clientY);
    renderCaptureSelection();
    return;
  }
  if (state.tool === "select") {
    deselectAnnotation();
    return;
  }

  // Ctrl+Click: stamp annotation around the hovered DOM element
  if (e.ctrlKey) {
    const handled = ctrlClickAnnotate(e.clientX, e.clientY);
    if (handled) {
      e.preventDefault();
      e.stopPropagation();
      return;
    }
  }

  e.preventDefault();
  e.stopPropagation();

  state.drawing = true;
  const { x, y } = snapPoint(e.clientX, e.clientY);
  state.startX = x;
  state.startY = y;
  updateSnapHint(null);

  const el = createAnnotationStart(x, y);
  if (el) {
    const layer = document.getElementById("ann-select-layer");
    document.getElementById("annotator-svg").insertBefore(el, layer);
    state.currentEl = el;
  }
}

function onDrawMove(e) {
  if (isCaptureInteractionActive()) {
    if (!state.captureDragging) return;
    e.preventDefault();
    updateCaptureDrag(e.clientX, e.clientY);
    return;
  }
  if (!state.drawing || !state.currentEl) return;
  e.preventDefault();
  const { x, y, snapped, rect } = snapPoint(e.clientX, e.clientY);
  updateSnapHint(snapped ? rect : null);
  updateAnnotation(state.currentEl, state.startX, state.startY, x, y, e.shiftKey);
}

function onDrawEnd(e) {
  if (isCaptureInteractionActive()) {
    if (!state.captureDragging) return;
    endCaptureDrag(e.clientX, e.clientY);
    return;
  }
  if (!state.drawing) return;
  state.drawing = false;
  updateSnapHint(null);

  if (state.currentEl) {
    const { x, y } = snapPoint(e.clientX, e.clientY);
    updateAnnotation(state.currentEl, state.startX, state.startY, x, y, e.shiftKey);

    if (isTrivial(state.currentEl)) {
      state.currentEl.remove();
    } else {
      const entry = { el: state.currentEl, type: state.tool };
      state.annotations.push(entry);
      makeSelectable(entry);
      if (state.tool === "callout") {
        const finishedSize = +state.currentEl.dataset.size;
        if (finishedSize > 0) state.lastCalloutSize = finishedSize;
        state.calloutCounter++;
      }
      if (state.tool === "text") {
        const fo = state.currentEl.querySelector(".ann-text-input");
        if (fo) fo.focus();
      }
      updateCaptureButtonTitle();
    }
    state.currentEl = null;
  }
}

function isTrivial(el) {
  const tag = el.tagName.toLowerCase();
  if (tag === "rect") {
    return Number(el.getAttribute("width")) < 4 && Number(el.getAttribute("height")) < 4;
  }
  if (tag === "foreignobject") {
    return Number(el.getAttribute("width")) < 4 && Number(el.getAttribute("height")) < 4;
  }
  if (tag === "ellipse") {
    return Number(el.getAttribute("rx")) < 4 && Number(el.getAttribute("ry")) < 4;
  }
  if (tag === "line") {
    const dx = Math.abs(Number(el.getAttribute("x2")) - Number(el.getAttribute("x1")));
    const dy = Math.abs(Number(el.getAttribute("y2")) - Number(el.getAttribute("y1")));
    return dx < 4 && dy < 4;
  }
  if (tag === "g") {
    return !el.dataset.size || Number(el.dataset.size) < 6;
  }
  return false;
}

// ── Shape creation / update ────────────────────────────────────────────────

function createAnnotationStart(x, y) {
  const c = state.color, sw = state.strokeWidth;

  switch (state.tool) {
    case "rect":
      return svgEl("rect", {
        x, y, width: 0, height: 0,
        fill: "none", stroke: c, "stroke-width": sw, rx: 2,
      });

    case "circle":
      return svgEl("ellipse", {
        cx: x, cy: y, rx: 0, ry: 0,
        fill: "none", stroke: c, "stroke-width": sw,
      });

    case "arrow":
      return svgEl("line", {
        x1: x, y1: y, x2: x, y2: y,
        stroke: c, "stroke-width": sw + 1,
        "marker-end": "url(#ann-arrow-head)", "stroke-linecap": "round",
      });

    case "text": {
      const fo = document.createElementNS(SVG_NS, "foreignObject");
      fo.setAttribute("x", x); fo.setAttribute("y", y);
      fo.setAttribute("width", "200"); fo.setAttribute("height", "40");
      fo.classList.add("ann-text-fo");
      const div = document.createElement("div");
      div.className = "ann-text-input";
      div.contentEditable = "true";
      div.style.color = c;
      div.style.fontSize = `${14 + sw * 2}px`;
      div.textContent = window.getSelection().toString().trim();
      fo.appendChild(div);
      return fo;
    }

    case "callout": {
      const g = document.createElementNS(SVG_NS, "g");
      // Start with lastCalloutSize so a click without drag produces the right size
      renderCallout(g, x, y, state.lastCalloutSize || 0, c, state.calloutCounter);
      return g;
    }

    case "blur": {
      const fo = document.createElementNS(SVG_NS, "foreignObject");
      fo.setAttribute("x", x); fo.setAttribute("y", y);
      fo.setAttribute("width", 0); fo.setAttribute("height", 0);
      const inner = document.createElement("div");
      inner.style.cssText =
        "width:100%;height:100%;backdrop-filter:blur(8px);" +
        "-webkit-backdrop-filter:blur(8px);background:rgba(0,0,0,0.15);";
      fo.appendChild(inner);
      return fo;
    }

    default:
      return null;
  }
}

function updateAnnotation(el, x1, y1, x2, y2, shiftKey) {
  const dx = x2 - x1, dy = y2 - y1;

  switch (state.tool) {
    case "rect": case "blur": {
      el.setAttribute("x",      Math.min(x1, x2));
      el.setAttribute("y",      Math.min(y1, y2));
      el.setAttribute("width",  Math.abs(dx));
      el.setAttribute("height", Math.abs(dy));
      break;
    }
    case "circle": {
      let rx = Math.abs(dx) / 2, ry = Math.abs(dy) / 2;
      if (shiftKey) { const r = Math.max(rx, ry); rx = r; ry = r; }
      el.setAttribute("cx", x1 + dx / 2);
      el.setAttribute("cy", y1 + dy / 2);
      el.setAttribute("rx", rx);
      el.setAttribute("ry", ry);
      break;
    }
    case "arrow":
      el.setAttribute("x2", x2);
      el.setAttribute("y2", y2);
      break;
    case "callout": {
      const dragR = Math.sqrt(dx * dx + dy * dy) / 2;
      // Small drag: keep last size as default; larger drag: use dragged size
      const r = dragR > 8 ? dragR : (state.lastCalloutSize || 12);
      renderCallout(el, x1, y1, r, state.color, state.calloutCounter);
      break;
    }
  }
}

// ── Undo / Clear / Delete selected ────────────────────────────────────────

function undo() {
  if (!state.annotations.length) return;
  const last = state.annotations.pop();
  if (last === state.selected) deselectAnnotation();
  last.el.remove();
  syncCalloutCounter();
  updateCaptureButtonTitle();
}

function clearAll() {
  deselectAnnotation();
  for (const a of state.annotations) a.el.remove();
  state.annotations = [];
  state.calloutCounter = 1;
  updateCaptureButtonTitle();
}

// ── Keyboard shortcuts ─────────────────────────────────────────────────────

function isTypingTarget(target) {
  if (!(target instanceof Element)) return false;
  if (target.isContentEditable) return true;
  return Boolean(
    target.closest("input, textarea, select, [contenteditable], [contenteditable='plaintext-only']")
  );
}

function onKeyDown(e) {
  if (state.capturePhase !== "idle" && e.key === "Escape") {
    e.preventDefault();
    cancelCaptureSelection();
    return;
  }
  if (isTypingTarget(e.target)) return;

  const isMod = e.ctrlKey || e.metaKey;
  const key = String(e.key || "").toLowerCase();
  if (state.capturePhase === "idle" && isMod && e.shiftKey && key === "v") {
    e.preventDefault();
    void captureVisibleAreaScreenshot();
    return;
  }
  if (state.capturePhase === "idle" && isMod && e.shiftKey && key === "f") {
    e.preventDefault();
    void captureFullPageScreenshot();
    return;
  }
  if (state.capturePhase === "idle" && !isMod && key === "v") {
    e.preventDefault();
    void captureVisibleAreaScreenshot();
    return;
  }
  if (state.capturePhase === "idle" && !isMod && key === "f") {
    e.preventDefault();
    void captureFullPageScreenshot();
    return;
  }
  if (state.capturePhase !== "idle") return;

  if ((e.key === "Delete" || e.key === "Backspace") && state.selected) {
    e.preventDefault();
    deleteSelected();
    return;
  }
  if (isMod && key === "z") { e.preventDefault(); undo(); return; }
  if (isMod) return;

  const map = { s: "select", r: "rect", c: "circle", a: "arrow", t: "text", n: "callout", b: "blur" };
  if (map[key]) setTool(map[key]);
}

// ── Annotation JSON import/export ─────────────────────────────────────────

function serializeAnnotation(entry) {
  const type = entry.type;
  const geom = getGeom(type, entry.el);
  if (!geom) return null;

  if (type === "rect" || type === "circle" || type === "arrow") {
    return {
      type,
      geom,
      stroke: entry.el.getAttribute("stroke") || state.color,
      strokeWidth: Number(entry.el.getAttribute("stroke-width")) || state.strokeWidth,
    };
  }
  if (type === "blur") {
    return { type, geom };
  }
  if (type === "text") {
    const input = entry.el.querySelector(".ann-text-input");
    return {
      type,
      geom,
      text: input?.textContent || "",
      color: input?.style.color || state.color,
      fontSize: input?.style.fontSize || "16px",
    };
  }
  if (type === "callout") {
    const number = Number.parseInt(entry.el.dataset.number || "", 10);
    return {
      type,
      geom,
      fill: entry.el.dataset.color || state.color,
      number: Number.isFinite(number) && number > 0 ? number : 1,
    };
  }
  return null;
}

function createAnnotationFromJson(item) {
  if (!item || typeof item !== "object" || typeof item.type !== "string") return null;
  const type = item.type;
  const geom = item.geom;
  let el = null;

  if (type === "rect") {
    el = svgEl("rect", {
      x: 0, y: 0, width: 0, height: 0, rx: 2,
      fill: "none",
      stroke: item.stroke || state.color,
      "stroke-width": Number(item.strokeWidth) || state.strokeWidth,
    });
    setGeom(type, el, geom);
  } else if (type === "circle") {
    el = svgEl("ellipse", {
      cx: 0, cy: 0, rx: 0, ry: 0,
      fill: "none",
      stroke: item.stroke || state.color,
      "stroke-width": Number(item.strokeWidth) || state.strokeWidth,
    });
    setGeom(type, el, geom);
  } else if (type === "arrow") {
    el = svgEl("line", {
      x1: 0, y1: 0, x2: 0, y2: 0,
      stroke: item.stroke || state.color,
      "stroke-width": Number(item.strokeWidth) || state.strokeWidth,
      "marker-end": "url(#ann-arrow-head)",
      "stroke-linecap": "round",
    });
    setGeom(type, el, geom);
  } else if (type === "blur") {
    el = document.createElementNS(SVG_NS, "foreignObject");
    const inner = document.createElement("div");
    inner.style.cssText =
      "width:100%;height:100%;backdrop-filter:blur(8px);" +
      "-webkit-backdrop-filter:blur(8px);background:rgba(0,0,0,0.15);";
    el.appendChild(inner);
    setGeom(type, el, geom);
  } else if (type === "text") {
    el = document.createElementNS(SVG_NS, "foreignObject");
    el.classList.add("ann-text-fo");
    const div = document.createElement("div");
    div.className = "ann-text-input";
    div.contentEditable = "true";
    div.style.color = item.color || state.color;
    div.style.fontSize = item.fontSize || "16px";
    div.textContent = typeof item.text === "string" ? item.text : "Text";
    el.appendChild(div);
    setGeom(type, el, geom);
  } else if (type === "callout") {
    el = document.createElementNS(SVG_NS, "g");
    const n = Number.parseInt(String(item.number ?? "1"), 10);
    const number = Number.isFinite(n) && n > 0 ? n : 1;
    renderCallout(
      el,
      Number(geom?.cx) || 0,
      Number(geom?.cy) || 0,
      Math.max(12, Number(geom?.r) || 12),
      item.fill || state.color,
      number
    );
  }

  if (!el) return null;
  return { el, type };
}

function loadAnnotationsPayload(payload) {
  if (!payload || typeof payload !== "object" || !Array.isArray(payload.annotations)) {
    throw new Error("Invalid annotation JSON format");
  }

  clearAll();
  const svg = document.getElementById("annotator-svg");
  const layer = document.getElementById("ann-select-layer");
  if (!svg || !layer) return;

  for (const item of payload.annotations) {
    const entry = createAnnotationFromJson(item);
    if (!entry) continue;
    svg.insertBefore(entry.el, layer);
    state.annotations.push(entry);
    makeSelectable(entry);
  }

  syncCalloutCounter();
  const latestCallout = state.annotations
    .filter((entry) => entry.type === "callout")
    .map((entry) => Number(entry.el.dataset.size))
    .filter((size) => Number.isFinite(size) && size > 0)
    .pop();
  state.lastCalloutSize = Number.isFinite(latestCallout) ? latestCallout : state.lastCalloutSize;
  updateCaptureButtonTitle();
  if (state.annotations.length > 0) setTool("select");
}

async function exportAnnotationsJson() {
  try {
    const payload = {
      version: 1,
      exportedAt: new Date().toISOString(),
      annotations: state.annotations.map(serializeAnnotation).filter(Boolean),
    };
    const blob = new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" });
    const dataUrl = await blobToDataUrl(blob);
    const saved = await saveDataUrlWithDialog(dataUrl, `annotations-${getTimestamp()}.json`);
    showToast(saved ? "Annotations JSON saved." : "Save canceled.");
  } catch (err) {
    console.error("[Annotator] Could not export annotations:", err);
    showToast("Could not export annotations JSON.", "error", 2800);
  }
}

function importAnnotationsJson() {
  const input = document.createElement("input");
  input.type = "file";
  input.accept = "application/json,.json";
  input.style.display = "none";
  document.body.appendChild(input);
  window.addEventListener("focus", () => {
    setTimeout(() => input.remove(), 0);
  }, { once: true });
  input.addEventListener("change", async () => {
    try {
      const file = input.files && input.files[0];
      if (!file) return;
      const text = await file.text();
      const payload = JSON.parse(text);
      loadAnnotationsPayload(payload);
      showToast("Annotations JSON loaded.", "success");
    } catch (err) {
      console.error("[Annotator] Could not import annotations:", err);
      showToast("Could not load annotations JSON.", "error", 2800);
    } finally {
      input.remove();
    }
  }, { once: true });
  input.click();
}

// ── Persistent settings ────────────────────────────────────────────────────

const SETTINGS_KEYS = ["tool", "color", "strokeWidth"];

function saveSettings() {
  browser.storage.local.set({
    tool: state.tool,
    color: state.color,
    strokeWidth: state.strokeWidth,
  }).catch(() => {});
}

async function loadSettings() {
  try {
    const data = await browser.storage.local.get(SETTINGS_KEYS);
    if (data.tool)        state.tool        = data.tool;
    if (data.color)       state.color       = data.color;
    if (data.strokeWidth) state.strokeWidth = data.strokeWidth;
  } catch (_) {
    // ignore — keep defaults
  }
}

// ── Message listener ───────────────────────────────────────────────────────

browser.runtime.onMessage.addListener((msg) => {
  if (msg.type === "TOGGLE") {
    if (state.active) {
      teardown();
    } else {
      state.active = true;
      loadSettings().then(() => {
        inject();
        setTool(state.tool);
      });
    }
    return;
  }
  onExtensionMessage(msg);
});
