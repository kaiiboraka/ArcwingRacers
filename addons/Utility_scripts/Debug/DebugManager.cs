using System.Diagnostics;
using Godot;
using Godot.Collections;

public partial class DebugManager : CanvasLayer
{
	public static DebugManager Instance { get; private set; }

	public DebugLogger DEBUG;

	[Export] public bool Enabled { get; private set; } = true;
	[Export] private PackedScene PropertyEntryScene;

	[Signal] public delegate void PropertyChangedEventHandler(string which, string value);
	[Signal] public delegate void VisualsActiveChangedEventHandler(bool visualsActive);

	private Vector2 game_size = new Vector2(
		(float)ProjectSettings.GetSetting("display/window/size/width"),
		(float)ProjectSettings.GetSetting("display/window/size/height")
	);

	private Dictionary<string, string> HUDProperties = new();
	private Array<PropertyEntry> entries = new();
	private VBoxContainer PropertyList;
	// private Control RuntimeStateViewer;

	public Node DebugInputs { get; private set; }

	private bool visualsActive = true;
	public bool VisualsActive
	{
		get => visualsActive;
		private set
		{
			visualsActive = value && Enabled;
			Visible = visualsActive;
			EmitSignalVisualsActiveChanged(visualsActive);
		}
	}


	public override void _EnterTree()
	{
		AddToGroup("Debug");
		base._EnterTree();
	}

	public override void _ExitTree()
	{
		RemoveFromGroup("Debug");
		base._ExitTree();
	}

	// Called when the node enters the scene tree for the first time.

	public override void _Ready()
	{
		if (Instance == null)
		{
			Instance = this;
		}

		DebugInputs = GetNode<Node>("DebugInputs");
		// RuntimeStateViewer = GetNode<Control>("%RuntimeStateViewer");
		// RuntimeStateViewer.Visible = true;

		DEBUG = new DebugLogger(this);

		PropertyEntryScene ??= GD.Load<PackedScene>("res://Scenes/UI/Debug/PropertyEntry.tscn");

		// this.DeferredCall(_LateReady);
		Callable.From(_LateReady).CallDeferred();
	}

	private async void _LateReady()
	{
		await ToSignal(GetTree(), SceneTree.SignalName.PhysicsFrame);

		// player ??= GetTree().GetFirstNodeInGroup("Player") as PlayerBody;
		// if (player?.PlayerCamera == null)
		// {
		// 	player?.InitCamera();
		// }

		UpdateHUDValues();
		FillDebugHUD();
		VisualsActive = visualsActive;
	}

	public static void Trace(string message)
	{
		Instance?.DEBUG.Trace(message);
	}

	public static void Debug(string message)
	{
		Instance?.DEBUG.Debug(message);
	}

	public static void Warning(string message)
	{
		Instance?.DEBUG.Warning(message);
	}

	public static void Error(string message)
	{
		Instance?.DEBUG.Error(message);
	}

	public static void Info(string message)
	{
		Instance?.DEBUG.Info(message);
	}


	private void FillDebugHUD()
	{
		HUDProperties ??= new();

		PropertyList = GetNode<VBoxContainer>("%PropertyList");
		foreach (var child in PropertyList.GetChildren())
		{
			child.QueueFree();
		}

		entries = new();
		foreach (var (label, value) in HUDProperties)
		{
			// Debug.Assert(PropertyEntryScene != null, "PropertyEntryScene cannot be null");
			var propertyEntry = PropertyEntryScene.Instantiate<PropertyEntry>();

			PropertyList.AddChild(propertyEntry);
			propertyEntry.Owner = this;

			propertyEntry.PropertyText = label;
			propertyEntry.ValueText = value;

			PropertyChanged += propertyEntry.UpdateValueText;
			entries.Add(propertyEntry);
		}
	}

	public void ToggleVisibility()
	{
		VisualsActive = !VisualsActive;
	}

	public override void _Process(double delta)
	{
		UpdateHUDValues();
		base._Process(delta);
	}

	public void UpdateProperty<T>(string which, T value)
	{
		if (!VisualsActive) return;

		string propertyValue = value.ToString();
		HUDProperties[which] = propertyValue;
		EmitSignalPropertyChanged(which, propertyValue);
	}

	private void UpdateHUDValues()
	{
		if (!VisualsActive) return;

		UpdateProperty_GameInfo();
		UpdateProperty_Movement();
	}

	private void UpdateProperty_Movement()
	{
		UpdateProperty("~~_ Movement _~~", "~~~~~~~~~~~~");
	}

	private void UpdateProperty_GameInfo()
	{
		UpdateProperty("~~_ Game _~~", "~~~~~~~~~~~~");
		UpdateProperty("Game Time", ((double)Time.GetTicksMsec()).MsToSec(0));
		UpdateProperty("Time Scale Steps", DebugInputs.Get("time_scale_steps"));
		UpdateProperty("Time Scale", Engine.TimeScale);
	}

	private void UpdateProperty_Movement()
	{
	}



}