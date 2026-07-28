using System;
using System.Text;
using Godot;
using Godot.Collections;

public static class GodotExtensions
{
    public static float GetSeconds(this Node node, int precision = 2)
    {
        return (Time.GetTicksMsec() / 1000f).RoundToPrecision(precision);
    }

    public static void DeferredCall(this Node node, Action action)
    {
        Callable.From(action).CallDeferred();
    }

    public static Vector2 RemoveFirstPoint(this Curve2D curve)
    {
        Vector2 firstPoint = curve.GetPointPosition(0);
        curve.RemovePoint(0);
        return firstPoint;
    }

    public static Vector2 RemoveLastPoint(this Curve2D curve)
    {
        Vector2 lastPoint = curve.GetPointPosition(curve.PointCount - 1);
        curve.RemovePoint(curve.PointCount-1);
        return lastPoint;
    }

    public static void Print(this string text)
    {
        GD.Print(text);
    }

    public static string Repeat(this string s, int n)
    {
        return new StringBuilder(s.Length * n).Insert(0, s, n).ToString();
    }


    // TODO: rewrite without FileSystem dependency

    public static string ToHex(this Color color)
    {
        return "#" + color.ToHtml();
    }

    // public static void AlignWithY(this Node2D node, Vector2 new_y)
    // {
    //     var xform = node.Transform;
    //
    //     xform.BasisXform().Y = new_y;
    //
    //     xform.basis.x = -xform.basis.z.cross(new_y)
    //     xform.basis = xform.basis.orthonormalized()
    // return xform
    // }
}