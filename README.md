# Re Hide & Seek Mod and API

## Configuration

| Config var                    | Default | Min | Max          | Description                                                             |
| :---------------------------- | :-----: | :-: | :----------: | :---------------------------------------------------------------------- |
| enabled                       | 1       | 0   | 1            | Sets whether HNS is enabled or not <br/>`0` disabled <br/>`1` enabled   |
| timer                         | 5       | 0   | 60           | Time before the start of the game (at this time the CT team is freezed) |
| flashbangs                    | 2       | 0   | 99           | The number of flashbangs given to the player                            |
| hegrenades                    | 0       | 0   | 99           | The number of hegrenades given to the player                            |
| smokegrenades                 | 1       | 0   | 99           | The number of smokegrenades given to the player                         |

## Map configuration

Each map can have a specific config file for which it will load on map change. This config file will be loaded in addition to the standard hns_config.ini file.

The file is to be located at *amxmodx/configs/hns/maps/mapname.ini*. For example, for hns_floppytown you would create the config file *amxmodx/configs/hns/maps/hns_floppytown.ini*.

You also can able to create config files for map prefixes. To do this, create a file called prefix_mapprefix.ini, where *mapprefix* would mean hns, c21, rayish, ect. All prefix config files go in the same location as per map, the amxmodx/configs/hns/maps/ directory.

For example, if you want to reduce the timer on c21 maps you would put this in *amxmodx/configs/hns/maps/prefix_c21.ini*:

<pre>
timer = 2
</pre>


## License

The Re Hide & Seek is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).