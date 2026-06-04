# Notes

## Screen

Make new screen session with a given layout

```sh
screen -R <name> -c <layout-filepath>
```

Kill a screen session

```sh
screen -S <name> -X quit
```

Internal screen commands [ref](https://www.gnu.org/software/screen/manual/screen.html)

### Within a screen session

- `ctrl+c` create a new terminal
- `ctrl+[0-9]` switch to terminal
- 