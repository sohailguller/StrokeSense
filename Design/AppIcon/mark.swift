// Constructs the StrokeSense mark as vector geometry and writes the two SVG layers
// used by StrokeSense/AppIcon.icon.
//
//   swiftc -O mark.swift -o /tmp/mark && /tmp/mark ../../StrokeSense/AppIcon.icon/Assets
//
// The idea: StrokeSense teaches one skill, noticing when one side stops matching the
// other (a face that droops, an arm that drifts). The mark is a brain seen from above:
// two hemispheres, one sitting a little lower and fading. The gap between them is the
// moment you notice.
//
// Construction (1024 x 1024 canvas, y down):
//   Outline   superellipse |x/a|^n + |y/b|^n = 1, n = 2.1, a = 244, b = 282,
//             narrower at the front: a(y) = a * (1 + k * y / b), k = 0.08.
//   Unit      u = 36. The fissure and every fold are exactly one unit wide.
//   Folds     two per hemisphere, at 37% and 65% of the height. Each leaves the edge at a
//             right angle and fans away from the other, like the central and
//             parieto-occipital sulci.
//   Drop      the right hemisphere sits 32 lower (about 5% of the height). The pair is
//             lifted by half of that so it stays optically centered.
//   Softening a morphological opening with radius 5 rounds every convex corner.

import CoreGraphics
import Foundation

let canvas: CGFloat = 1024
let cx: CGFloat = 512
let cy: CGFloat = 512
let a: CGFloat = 244
let b: CGFloat = 282
let n: CGFloat = 2.1
let k: CGFloat = 0.08
let u: CGFloat = 36
let drop: CGFloat = 32
let soften: CGFloat = 5

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

/// A fold that leaves the lateral edge at a right angle, then bends toward its end.
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
    return p.copy(strokingWithWidth: u, lineCap: .round, lineJoin: .round, miterLimit: 10)
}

func softened(_ shape: CGPath) -> CGPath {
    let eroded = shape.subtracting(shape.copy(strokingWithWidth: soften * 2, lineCap: .round, lineJoin: .round, miterLimit: 10))
    return eroded.union(eroded.copy(strokingWithWidth: soften * 2, lineCap: .round, lineJoin: .round, miterLimit: 10))
}

func leftHemisphere() -> CGPath {
    let half = CGPath(rect: CGRect(x: 0, y: 0, width: cx - u / 2, height: canvas), transform: nil)
    var shape = outline().intersection(half)
    shape = shape.subtracting(fold(at: 0.37, rise: 0.08, reach: 0.5))
    shape = shape.subtracting(fold(at: 0.65, rise: -0.08, reach: 0.5))
    return softened(shape)
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

var lift = CGAffineTransform(translationX: 0, y: -drop / 2)
let left = leftHemisphere().copy(using: &lift)!
var mirror = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: canvas, ty: drop / 2)
let right = leftHemisphere().copy(using: &mirror)!

let out = CommandLine.arguments[1]
try svg(left).write(toFile: out + "/1_Left.svg", atomically: true, encoding: .utf8)
try svg(right).write(toFile: out + "/0_Right.svg", atomically: true, encoding: .utf8)
