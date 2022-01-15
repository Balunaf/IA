///////////////////////////////////////////////////////////////////////////
//
// The main program
// ================
// v 1.0 (c) Guillaume Hutzler, 2021
//
///////////////////////////////////////////////////////////////////////////
// TODO
// - corriger quelques bugs
// - ajouter la possibilite de détruire les murs avec des bullets 
// - optimiser la recherche de patch libre autour
// - optimiser la perception
///////////////////////////////////////////////////////////////////////////

// the main object to control the game
Simulation game;
// the mouse
Mouse mouse;

///////////////////////////////////////////////////////////////////////////
//
// defines the dimensions of the window depending on
// - the dimensions of the environment 
// - the size of a patch (in pixels) 
//
///////////////////////////////////////////////////////////////////////////
void settings() {
  size(nbPatchesX * patchSize, nbPatchesY * patchSize + 100);
}

///////////////////////////////////////////////////////////////////////////
//
// creates and initializes the game
// ================================
//
///////////////////////////////////////////////////////////////////////////
void setup() {
  imageMode(CENTER);
  textAlign(CENTER, CENTER);
  game = new Simulation();
  game.setup();
}

///////////////////////////////////////////////////////////////////////////
//
// main loop
// =========
//
///////////////////////////////////////////////////////////////////////////
void draw() {
  // activates every agent of the game
  game.go();
  // updates the display
  game.display();
  // makes the clock advance 
  game.tick();
}

///////////////////////////////////////////////////////////////////////////
//
// user interaction
// ================
//
///////////////////////////////////////////////////////////////////////////
void keyTyped() {
  switch(key) {
    // to display the state of the "brain"
  case '0':
  case '1':
  case '2':
  case '3':
  case '4':
  case '5':
  case '6':
  case '7':
  case '8':
  case '9':
    if (display == 10 + key - '0')
      display = -1;
    else
      display = 10 + key - '0';
    break;
    // to display energy
  case 'e':
    if (display == ENERGY)
      display = -1;
    else
      display = ENERGY;
    break;
    // to display the amount of food carried by the agents
  case 'f':
    if (display == C_FOOD)
      display = -1;
    else
      display = C_FOOD;
    break;
    // to display the number of missiles carried by the agents
  case 'm':
    if (display == MISSILES)
      display = -1;
    else
      display = MISSILES;
    break;
    // to display (or not) the patches
  case 'p':
    displayPatches = !displayPatches;
    break;
    // to display (or not) the range of perception
  case 'r':
    displayRange = !displayRange;
    break;
  }
}
