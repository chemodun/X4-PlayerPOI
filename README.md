# Player POI

Implementation of player POI (point of interest) system, allowing players to create and manage custom POIs in on the map and in space.

## Features

- **Creation of custom POIs** on the map at any location.
- **Assignment of POIs to objects** on map or in space (non player stations and gates).
- **Automatic name generation** for POIs based on the assigned object or location.
- **POI management tab** in the Property Owned Information.
- **Context menu** for POIs in space and on the map, allowing to rename or self-destruct POIs.
- **Optimized rename window location** to be close to the selected POI.

## Requirements

- **X4: Foundations**: Version 8.00HF3 or newer.
- **UI Extensions and HUD**: Version v8.0.4.0 or higher by [kuertee](https://next.nexusmods.com/profile/kuertee?gameId=2659).
  - Available on Nexus Mods: [UI Extensions and HUD](https://www.nexusmods.com/x4foundations/mods/552)
- **Mod Support APIs**: Version 1.95 or higher by [SirNukes](https://next.nexusmods.com/profile/sirnukes?gameId=2659).
  - Available on Steam: [SirNukes Mod Support APIs](https://steamcommunity.com/sharedfiles/filedetails/?id=2042901274)
  - Available on Nexus Mods: [Mod Support APIs](https://www.nexusmods.com/x4foundations/mods/503)

## Compatibility

- With [Custom Tabs](https://www.nexusmods.com/x4foundations/mods/842) mod by [Mycu](https://www.nexusmods.com/x4foundations/users/7018859)

## Installation

- **Steam Workshop**: [Player POI](https://steamcommunity.com/sharedfiles/filedetails/?id=)
- **Nexus Mods**: [Player POI](https://www.nexusmods.com/x4foundations/mods/)

## Usage

### Creating a POI on the map

To create a `POI` on the map, simply open the holomap, right-click on any location and select `Create POI at ...` from the context menu. A new POI will be created at the selected location with a default name based on the coordinates.

![Creating a POI on the map](docs/images/create_poi_on_map_at_any_point.png)

The created `POI` will be visible on the map and in the `Player POI` tab of the Property Owned Information, where you can manage it (like renaming or self-destructing it) using the context menu.

![POI created at the selected point on the map](docs/images/created_poi_at_point_on_map.png)

Additionally, you can assign a `POI` to an object on the map (like a station or a gate) by right-clicking on the object and selecting `Assign POI` from the context menu. The `POI` will be created and automatically located near the object, and its name will be generated based on the object's name.

Context menu for assigning a `POI` to an object on the map is exactly the same as in space, see the next section for details.

### Creating a POI in space

In space, you can only assign a `POI` to an object (like a station or a gate) by right-clicking on the object and selecting `Assign POI` from the context menu. The `POI` will be created and automatically located near the object, and its name will be generated based on the object's name.

![Assigning a POI to an object in space](docs/images/assign_poi_on_object_in_space.png)

The created `POI` will be visible in space, on a map and in the `Player POI` tab of the Property Owned Information, where you can manage it (like renaming or self-destructing it) using the context menu.

![POI assigned to an object in space](docs/images/poi_assigned_on_object_in_space.png)

### Managing POIs

You can manage your created `POIs` in space, on map and in the `Player POI` tab of the Property Owned Information.
All management actions (like renaming or self-destructing a `POI`) are available in the context menu, which can be accessed by right-clicking on a `POI` in space, on the map or in the tab.

#### Managing POIs in space

There is how the context menu for a `POI` in space looks like:

![POI context menu in space](docs/images/poi_context_menu_in_space.png)

##### Renaming a POI in space

When you select "Rename" from the context menu of a `POI` in space, a rename window will open, allowing you to enter a new name for the `POI`.

![Renaming a POI in space](docs/images/poi_rename_in_space.png)

As soon as you enter a new name and confirm it, the `POI` will be renamed.

![POI renamed in space](docs/images/poi_renamed_in_space.png)

#### Managing POIs on the map

Context menu for a `POI` on the map is the same as in space, but with an additional option to center the map on the `POI`:

![POI context menu on map](docs/images/poi_context_menu_on_map.png)

#### Managing POIs in the Player POI tab

There is an additional tab in the Property Owned Information called `Player POI`, where you can see all your created `POIs` in one place. You can also manage your `POIs` from this tab using the same context menu as in space and on the map.

![POI tab in Property Owned Information](docs/images/poi_tab_in_property_owned.png)

##### Self-destructing a POI

When you select "Self-destruct" from the context menu of a `POI`, the `POI` will be immediately removed from the game. This action cannot be undone, so use it with caution.
There  is an example of a `POI` that is about to be self-destructed in the following screenshot:

![POI context menu on tab](docs/images/poi_context_menu_on_tab.png)

And here is how the list of `POIs` looks like after the `POI` has been self-destructed:

![POI tab after self-destruct](docs/images/poi_tab_after_self_destruct.png)

##### Renaming a POI from the "Player POI" tab

When you select "Rename" from the context menu of a `POI` in the `Player POI` tab, a rename window will open, allowing you to enter a new name for the `POI`.

![POI rename on tab](docs/images/poi_rename_on_tab.png)

As soon as you enter a new name and confirm it, the `POI` will be renamed.

![POI renamed on tab](docs/images/poi_renamed_on_tab.png)

##### Player POI tab in the Property Owned Information

One more example of the `Player POI` tab in the Property Owned Information, showing several created `POIs` in space and on the map:

![POI tab and map](docs/images/poi_tab_and_map.png)

### Options

You can configure the mod in the options menu, which can be accessed from the `Player POI` item in `Extension Options`  menu.

![Extension Options](docs/images/extension_options.png)

In the options menu, you can enable or disable `optimized` rename window location, which will make the rename window appear near the selected `POI` instead of the center of the screen.

![POI Options](docs/images/poi_options.png)

There are two screenshots showing the difference between `optimized` and `standard` rename window location:

- `Optimized` rename window location (enabled):

  ![Rename Optimized Position](docs/images/rename_optimized_position.png)
- `Standard` rename window location (disabled):

  ![Rename Standard Position](docs/images/rename_standard_position.png)

In addition, for the resolving issues, you can enable debug logging in the options menu, which will log detailed information about the mod's operations to the X4 log file. This can be helpful for troubleshooting and understanding how the mod works.

## Video

[Video demonstration of the . Version 1.00](https://www.youtube.com/watch?v=0)

## Credits

- **Author**: Chem O`Dun, on [Nexus Mods](https://next.nexusmods.com/profile/ChemODun/mods?gameId=2659) and [Steam Workshop](https://steamcommunity.com/id/chemodun/myworkshopfiles/?appid=392160)
- *"X4: Foundations"* is a trademark of [Egosoft](https://www.egosoft.com).

## Acknowledgements

- [EGOSOFT](https://www.egosoft.com) — for the X series.
- [kuertee](https://next.nexusmods.com/profile/kuertee?gameId=2659) — for the `UI Extensions and HUD` that makes this extension possible.
- [SirNukes](https://next.nexusmods.com/profile/sirnukes?gameId=2659) — for the `Mod Support APIs` that power the UI hooks.

## Changelog


### [1.00] - 2026-02-??

- **Added**
  - Initial public version
