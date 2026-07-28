// Taken from https://forum.unity.com/threads/change-gameobject-layer-at-run-time-wont-apply-to-child.10091/
/* Usage:
    GameObject obj;
    obj.SetLayer(LayerMask.NameToLayer("Player"));
 */
using Godot;

public static class Node2DExtensions
{
    public static StringName idName(this Node2D self) => self.Name + self.GetInstanceId();
    
    public static void FlipXScale(this Node2D transform)
    {
        transform.Scale = transform.Scale.FlipX();
    }

    public static void FlipYScale(this Node2D transform)
    {
        transform.Scale = transform.Scale.FlipY();
    }

    public static bool FacingLeft(this Node2D transform)
    {
        return transform.Scale.X.IsNeg();
    }

    public static void FaceLeft(this Node2D transform)
    {
        if (transform.FacingLeft()) return;
        transform.Scale = new Vector2(-Mathf.Abs(transform.Scale.X), transform.Scale.Y);
    }

    public static bool FacingRight(this Node2D transform)
    {
        return transform.Scale.X.IsPos();
    }

    public static void FaceRight(this Node2D transform)
    {
        if (transform?.FacingRight() ?? true) return;
        transform.Scale = new Vector2(Mathf.Abs(transform.Scale.X), transform.Scale.Y);
    }

    public static bool FacingDown(this Node2D transform)
    {
        return transform.Scale.Y.IsPos();
    }

    public static void FaceDown(this Node2D transform)
    {
        if (transform.FacingDown()) return;
        transform.Scale = transform.Scale.FaceDown();
    }

    public static bool FacingUp(this Node2D transform)
    {
        return transform.Scale.Y.IsNeg();
    }

    public static void FaceUp(this Node2D transform)
    {
        if (transform.FacingUp()) return;
        transform.Scale = transform.Scale.FaceUp();
    }
}