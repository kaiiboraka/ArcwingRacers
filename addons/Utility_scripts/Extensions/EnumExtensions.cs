using System;
using Godot;

public static class EnumExtensions
{
    public static string GetValueSubstring(string value)
    {
        return value.Substring(value.LastIndexOf('.') + 1);
    }
}