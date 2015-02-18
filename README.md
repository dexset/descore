## Core part of D Extended Set (DES) library

DESCore does not have external dependencies

* `des.math`: some math concepts and funcs

    * `linear`: vectors and matrix with fix and dynamic
        dimensions, quaternions, etc

    * `method`: approx funcs, differential, integral, statistics

    * `combin`: combinatorics

    * `basic`: easy method to create structs with basic
        math ops (`+`,`-`,`*`,`/`)

* `des.space`: linear algebra oriented 3d views

    * `node`: `SpaceNode` interface for objects, that can be viewed
    
    * `camera`: `interface Camera : SpaceNode`, manipution with
        nodes matrix to view objects in camera space

    * `resolver`: part of camera, calc transform matrix from one node local
      coord system to other node coord system

* `des.il`: working with multidimension images
    
    * `image`: image struct

    * `func`: copy, paste funcs (loading from file in `des` package,
      `descore` doesn't have external dependences )

    * `region`: multidimension rectangle region

    * `util`: converts from line index to dimension index, calc layers size, etc

* `des.flow`: multithreading wrap
    
    * `element`: work element in thread

    * `event`: struct for communication between elements

    * `signal`: control state struct

    * `thread`: main wrap for `core.thread`

* `des.util`: some utilites, that used in many parts of DES 

    * `arch`: external memory managment (such as OpenGL buffers),
        signal-slot, etc

    * `data`: data types enums, work with "raw" data (`void*`)

    * `localization`: multilanguage support

    * `logsys`: logging system

    * `stdext`: extended standart functions from std (algorithms, string, traits)

    * `testsuite`: some aux funcs for unittesting

    * `colorparse`: parse strings like `#FF00FF` to RGB components

    * `helpers`: application path utils (reading files)

    * `socket`: simple socket

    * `timer`: simple timer

Documentation orient to [harbored-mod](https://github.com/kiith-sa/harbored-mod)

to build doc:
```sh
cd path/to/descore
path/to/harbored-mod/bin/hmod
```
