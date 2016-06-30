## El Asno Alado

Based on [cfndsl](https://github.com/stevenjack/cfndsl)

### Build 

```make image```

This will build the docker environment for `asno` to run

### Create a json that describes a stack

``` make TEMPLATE=simple-asg VARIABLES=centauro-asg json```

This outputs a cloudformation json template named `simple-asg.json` to the `output` dir. This task assumes there is a `variables` directory that contains a file named `centauro-asg.yml`

### To create a stack 

```make TEMPLATE=simple-asg VARIABLES=centauro-asg STACK_NAME=centauro create```

This creates a cloudformation stack named `centauro-dev` based on the `simple-asg.rb` template

### To delete a stack 

```make STACK_NAME=centauro delete```

This deletes the stack called `centauro-dev`

### de F. Isabel Campoy

#### El asno alado de Paul

(Inspirado en un cuadro de Picasso, 1923)

```poema-da-hora
¡Arre, borriquito, arre!
–le digo yo a mi borrico,
que no se quiere mover.
–¡Arre, te digo, burro!
Pero no hay nadie más terco que él.
Así que yo me invento que vamos
mi burrito y yo trotandito, trotando,
por un camino a beber
agua de una fuente mágica
que lo hará ligero de patas
y ya más nunca
querrá dejar de correr.
Soñamos cruzar los países
solo en cuestión
de un momento,
y que conocemos a reyes y duques
que quieren escuchar este cuento.
Y al regresar a casa
aunque mi traje y mi sombrero
estén tan limpios como sus patas
solo él y yo sabemos cómo cansan
los honores
y las largas cabalgatas.
```
