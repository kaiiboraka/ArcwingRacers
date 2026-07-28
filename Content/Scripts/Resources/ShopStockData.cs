using Godot;
using Godot.Collections;

[GlobalClass]
public partial class ShopStockData : Resource
{
    [Export] public Array<ShopItemData> AvailableItems { get; private set; } = new();
}
