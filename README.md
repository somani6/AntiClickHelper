# AntiClickHelper

**AntiClickHelper** is a World of Warcraft addon designed to help players transition from clicking abilities to using keybinds. It provides immediate audio and visual feedback whenever you click an ability on your action bars, encouraging you to rely on muscle memory instead.

## Features

*   **Click Detection**: Monitors your action bars and detects when an ability is clicked with the mouse instead of a keybind.
*   **Audio Feedback**: Plays a customizable sound (via LibSharedMedia) whenever you click an ability.
*   **Hardmode (Visual Punishment)**:
    *   A black circle appears around your mouse cursor when you click.
    *   **Growth**: The circle grows larger with every click, obscuring your view of the center of the screen.
    *   **Redemption**: The circle shrinks when you successfully use keybinds while in combat.
*   **Punish Unbound**: Option to punish clicks even if the button has no keybind assigned.
*   **Configurable**:
    *   Select exactly which action bars to monitor.
    *   Toggle Hardmode on/off.
    *   Choose your preferred alert sound.

## Supported Action Bars

AntiClickHelper works out-of-the-box with:
*   **Blizzard Standard Action Bars**
*   **Dominos**
*   **Bartender4**
*   **ElvUI Action Bars**

## How it Works

The addon hooks into your action buttons. When you click a button, it checks if that button has a keybind assigned. If it does, and you clicked it with the mouse, it triggers the warning. It also monitors spell casts and compares the timing with your last mouse click to determine if a spell was cast via a keybind to reduce the Hardmode circle.

*   **Clicking**: Triggers sound + grows the circle.
*   **Keybinding**: Shrinks the circle (only in combat).

## Commands

*   `/ach` - Opens the configuration menu.

## Installation

1.  Download the addon.
2.  Extract it to your `Interface\AddOns` folder.
3.  (Optional) Install **WeakAuras_SharedMedia** for more sound options.