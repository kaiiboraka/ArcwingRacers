using Godot;

[GlobalClass]
public partial class ShopItemData : Resource
{
    [ExportGroup("Shop Properties")]
    [Export] public Texture2D ItemIcon { get; private set; }
    [Export] public string ItemName { get; private set; }
    [Export(PropertyHint.MultilineText)] public string ItemDescription { get; private set; }
    [Export] public int Price { get; private set; }
    [Export(PropertyHint.Range, "0.0,1.0")]
    public double Rarity { get; private set; }
}
