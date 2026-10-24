// Constructs the StrokeSense mark as vector geometry and writes the two SVG layers
// used by StrokeSense/AppIcon.icon.
//
//   swiftc -O mark.swift -o /tmp/mark && /tmp/mark ../../StrokeSense/AppIcon.icon/Assets
//
// The idea: a brain seen from above, its two hemispheres locked together like puzzle
// pieces. The brain says stroke at a glance; the puzzle says learning, putting the signs
// together. The right hemisphere is faded in Icon Composer: one side losing function,
// the sign StrokeSense teaches people to notice.
//
// Construction (1024 x 1024 canvas, y down):
//   Outline   superellipse |x/a|^n + |y/b|^n = 1, n = 2.15, a = 284, b = 328,
//             narrower at the front: a(y) = a * (1 + k * y / b), k = 0.08.
//   Unit      u = 38. The seam and every fold are exactly one unit wide.
//   Tabs      two puzzle tabs on the midline at ±30% of the half-height, one pointing
//             each way, so the halves truly interlock. Head radius 62, neck 62, reach 76.
//   Folds     two per hemisphere, at 30% and 72% of the height. Each leaves the edge at a
//             right angle and bends toward the middle.
//   Softening a morphological opening with radius 6 rounds every convex corner.

import CoreGraphics
import Foundation

let cx: CGFloat = 512
let cy: CGFloat = 512
let a: CGFloat = 284
let b: CGFloat = 328
let n: CGFloat = 2.15
let k: CGFloat = 0.08
let u: CGFloat = 38
let tabRadius: CGFloat = 62
let tabNeck: CGFloat = 62
let tabReach: CGFloat = 76
let soften: CGFloat = 6

func stroke(_ path: CGPath, _ width: CGFloat) -> CGPath {
    path.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 10)
}

func softened(_ shape: CGPath) -> CGPath {
    let eroded = shape.subtracting(stroke(shape, soften * 2))
    return eroded.union(stroke(eroded, soften * 2))
}

func outline() -> CGPath {
    let p = CGMutablePath()
    let steps = 720
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps) * 2 * .pi
        let c = cos(t), s = sin(t)
        let y = b * (s < 0 ? -1 : 1) * pow(abs(s), 2 / n)
        let x = a * (1 + k * y / b) * (c < 0 ? -1 : 1) * pow(abs(c), 2 / n)
        let pt = CGPoint(x: cx + x, y: cy + y)
        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
    }
    p.closeSubpath()
    return p
}

/// The left edge of the outline at height `y`.
func leftEdge(_ y: CGFloat) -> CGPoint {
    let yy = y - cy
    let x = a * (1 + k * yy / b) * pow(1 - pow(abs(yy / b), n), 1 / n)
    return CGPoint(x: cx - x, y: y)
}

/// A puzzle tab on the midline at height `y`, pointing right (+1) or left (-1).
func tab(at y: CGFloat, pointing direction: CGFloat) -> CGPath {
    let head = CGPath(ellipseIn: CGRect(x: cx + direction * tabReach - tabRadius, y: y - tabRadius,
                                        width: 2 * tabRadius, height: 2 * tabRadius), transform: nil)
    let neck = CGPath(rect: CGRect(x: direction > 0 ? cx - 2 : cx + 2 - tabReach, y: y - tabNeck / 2,
                                   width: tabReach, height: tabNeck), transform: nil)
    return head.union(neck)
}

/// A fold in the left hemisphere that leaves the edge at a right angle, then bends toward its end.
/// - Parameters:
///   - at: where it meets the edge, as a fraction of the height.
///   - rise: how far its end rises, as a fraction of the height (negative falls).
///   - reach: how far it reaches toward the midline, as a fraction of the half-width.
func fold(at: CGFloat, rise: CGFloat, reach: CGFloat) -> CGPath {
    let h = 2 * b
    let y = cy - b + h * at
    let edge = leftEdge(y)
    let tangent = CGPoint(x: leftEdge(y + 1).x - leftEdge(y - 1).x, y: 2)
    let length = hypot(tangent.x, tangent.y)
    let inward = CGPoint(x: tangent.y / length, y: -tangent.x / length)
    let end = CGPoint(x: cx - a * (1 - reach), y: y - h * rise)
    let distance = hypot(end.x - edge.x, end.y - edge.y)

    let p = CGMutablePath()
    p.move(to: CGPoint(x: edge.x - inward.x * u * 1.5, y: edge.y - inward.y * u * 1.5))
    p.addLine(to: edge)
    p.addCurve(to: end,
               control1: CGPoint(x: edge.x + inward.x * distance * 0.45, y: edge.y + inward.y * distance * 0.45),
               control2: CGPoint(x: end.x - distance * 0.3, y: end.y))
    return stroke(p, u)
}

// The left hemisphere's territory: everything left of the midline, plus the tab it sends
// right, minus the tab the right hemisphere sends left.
let territory = CGPath(rect: CGRect(x: 0, y: 0, width: cx, height: 1024), transform: nil)
    .union(tab(at: cy - b * 0.3, pointing: 1))
    .subtracting(tab(at: cy + b * 0.3, pointing: -1))
let seam = stroke(territory, u)
let folds = [fold(at: 0.30, rise: 0.06, reach: 0.42), fold(at: 0.72, rise: -0.06, reach: 0.42)]
var mirror = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 2 * cx, ty: 0)

var left = outline().intersection(territory).subtracting(seam)
var right = outline().subtracting(territory).subtracting(seam)
for f in folds {
    left = left.subtracting(f)
    right = right.subtracting(f.copy(using: &mirror)!)
}

func svg(_ path: CGPath) -> String {
    var d = ""
    func f(_ v: CGFloat) -> String { String(format: "%.2f", v) }
    path.applyWithBlock { element in
        let e = element.pointee, p = e.points
        switch e.type {
        case .moveToPoint: d += "M\(f(p[0].x)) \(f(p[0].y))"
        case .addLineToPoint: d += "L\(f(p[0].x)) \(f(p[0].y))"
        case .addQuadCurveToPoint: d += "Q\(f(p[0].x)) \(f(p[0].y)) \(f(p[1].x)) \(f(p[1].y))"
        case .addCurveToPoint: d += "C\(f(p[0].x)) \(f(p[0].y)) \(f(p[1].x)) \(f(p[1].y)) \(f(p[2].x)) \(f(p[2].y))"
        case .closeSubpath: d += "Z"
        @unknown default: break
        }
    }
    return """
    <svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
    <path fill="#FFFFFF" d="\(d)"/>
    </svg>

    """
}

let out = CommandLine.arguments[1]
try svg(softened(left)).write(toFile: out + "/1_Left.svg", atomically: true, encoding: .utf8)
try svg(softened(right)).write(toFile: out + "/0_Right.svg", atomically: true, encoding: .utf8)
