     ooooo   ooooo ooooooooooooo ooo        ooooo ooooooo  ooooo
     `888'   `888' 8'   888   `8 `88.       .888'  `8888    d8'
      888     888       888       888b     d'888     Y888..8P
      888ooooo888       888       8 Y88. .P  888      `8888'
      888     888       888       8  `888'   888     .8PY888.
      888     888       888       8    Y     888    d8'  `888b
     o888o   o888o     o888o     o8o        o888o o888o  o88888o
    ===========================================================
            Build with LUA, LUASOCKET, HTMX & _HYPERSCRIPT

[![Lua and Cypress Tests](https://github.com/syarul/todomvc-lua-luasocket-htmx-_hyperscript/actions/workflows/lua.yml/badge.svg)](https://github.com/syarul/todomvc-lua-luasocket-htmx-_hyperscript/actions/workflows/lua.yml)

| HTMX TodoMVC           | Link                                             |
| ---------------------- | ------------------------------------------------ |
| Go, Templ              | [🌄](https://github.com/syarul/todomvc-go-templ-htmx-_hyperscript)|
| Rust, Astra, Maud      | [🌠](https://github.com/syarul/todomvc-rust-astra-maud-htmx-_hyperscript)|
| ExpressJS, Typescript, React     | [✈️](https://github.com/syarul/htmx-todomvc)|
| AdonisJS, Typescript, React    | [🎡](https://github.com/syarul/todomvc-adonisjs-react-htmx-_hyperscript)|
| Lua, Luasocket             | [⛵](https://github.com/syarul/todomvc-lua-luasocket-htmx-_hyperscript)|

### E2E Testing

https://github.com/syarul/todomvc-adonisjs-react-htmx-_hyperscript/assets/2774594/fdcba602-73f2-499b-a106-152569d37e80


Emulating the functionalities of modern frameworks which is base on React TodoMVC. This demonstration serves to showcase that HTMX, when paired with _hyperscript, can replicate if not all the behaviors typically associated with most modern client framework with minimum needs to write javascript.

### Usage & Setup

Get latest Lua and all dependencies

```bash
sudo apt-get update
curl -LRO https://www.lua.org/ftp/lua-5.4.7.tar.gz
tar -xzvf lua-5.4.7.tar.gz
cd lua-5.4.7/
make linux
sudo make install
```

```bash
wget https://luarocks.org/releases/luarocks-3.11.1.tar.gz
tar zxpf luarocks-3.11.1.tar.gz
cd luarocks-3.11.1/
./configure && make && sudo make install
```

```bash
sudo luarocks install luasocket
sudo luarocks install luafilesystem
sudo luarocks install lua-cjson
sudo luarocks install luax
```

See [https://github.com/syarul/luax](https://github.com/syarul/luax) more to understand how transpiling HTML is done in Lua.

- run with `lua server.lua`
- visit `http://localhost:8888`
- for e2e testing, run in the root folder `git clone https://github.com/cypress-io/cypress-example-todomvc`
- `cd cypress-example-todomvc`
- `npm install`
- if you need to see the test in browser run `npm run cypress:open`
- for headless test `npm run cypress:run`

### HTMX

Visit [https://github.com/rajasegar/awesome-htmx](https://github.com/rajasegar/awesome-htmx) to look for HTMX curated infos

###

Todo

- Perf test (consolidate with other langs rust, zig, odin, ocaml, etc+)
