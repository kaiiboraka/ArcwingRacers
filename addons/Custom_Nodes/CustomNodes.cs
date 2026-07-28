using Godot;

[Tool]
public partial class CustomNodes : EditorPlugin
{
    public override void _EnterTree()
    {
        // Pattern for registering custom node types:
        // var script = GD.Load<Script>("res://path/to/script.gd");
        // var texture = GD.Load<Texture2D>("res://path/to/icon.png");
        // AddCustomType("NodeTypeName", "ParentType", script, texture);
    }

    public override void _ExitTree()
    {
        // Clean-up — remove each custom type:
        // RemoveCustomType("NodeTypeName");
    }
}