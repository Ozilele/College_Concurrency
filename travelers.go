package main

import (
	"fmt"
	"math/rand"
	"sync"
	"time"
)

const (
  m = 5
  n = 5
  k = 12
)

type Grid struct {
  mutex sync.Mutex
  grid [][]int // Krata z informacja o ilości podrózników,
  travelers int // AKtualna liczba podrózników
  travelerIDs []int // ID podrózników
}

type Coordinate struct {
  X int
  Y int
}

func (g *Grid) isBlank(x int, y int) bool {
  if x < 0 || y < 0 || x > m - 1 || y > n - 1 {
    return false
  }
  return g.grid[x][y] == -1 // if true then grid is blank in that place(no traveler is in that place)
}

func (g *Grid) initialize() { 
  g.grid = make([][]int, m)
  for i := range(g.grid) {
    g.grid[i] = make([]int, n)
    for j := range g.grid[i] {
      g.grid[i][j] = -1
    }
  }
  g.travelerIDs = make([]int, 0)
}

func (g *Grid) addTraveler() {
  if g.travelers >= m * n {
    return
  }
  var travelerID int
  row := rand.Intn(m)
  column := rand.Intn(n)
  // fmt.Printf("Wierzchołek (%d, %d)\n", row, column)
  g.mutex.Lock()
  if g.isBlank(row, column) { // if grid is blank in that place, add a traveler
    travelerID = len(g.travelerIDs)
    g.grid[row][column] = travelerID
    g.travelerIDs = append(g.travelerIDs, travelerID)
    fmt.Printf("Nowy podróżnik %d pojawił się w wierzchołku (%d, %d)\n", travelerID, row, column)
    g.travelers++
  }
  g.mutex.Unlock()
  if g.travelers >= m * n {
    return
  }
  time.Sleep(time.Millisecond * 150)
}

func (g *Grid) moveTraveler(travelerID int, moves chan string) {
  currentRow, currentCol := g.findTraveler(travelerID)
  neighbours := []Coordinate{
    {currentRow - 1, currentCol}, // Top neighbour
    {currentRow + 1, currentCol}, // Down neighbour
    {currentRow, currentCol + 1}, // Right neighbour
    {currentRow, currentCol - 1},  // Left neighbour
  }
  availableDirections := make([]Coordinate, 0)
  for _, neighbour := range neighbours {
    if g.isBlank(neighbour.X, neighbour.Y) {
      availableDirections = append(availableDirections, neighbour)
    }
  }
  if(len(availableDirections) > 0) {
    randomCoordinate := availableDirections[rand.Intn(len(availableDirections))] // random coordinate
    newRow, newColumn := randomCoordinate.X, randomCoordinate.Y
    g.mutex.Lock() // zabezpieczenie dostępu do Grida, bo wiele gorutyn moze próbować modyfikować ją równocześnie, mutex zapewnia ze tylko jedna gorutyna ma dostęp do tych danych w danym czasie, co eliminuje ryzyko race condition
    g.grid[newRow][newColumn] = travelerID
    g.grid[currentRow][currentCol] = -1 // reset position
    move_msg := fmt.Sprintf("Podróżnik %d przeszedł z wierzchołka (%d, %d) do wierzchołka (%d, %d)\n", travelerID, currentRow, currentCol, newRow, newColumn)
    moves <- move_msg
    // fmt.Printf("Podróżnik %d przeszedł z wierzchołka (%d, %d) do wierzchołka (%d, %d)\n", travelerID, currentRow, currentCol, newRow, newColumn)
    g.mutex.Unlock()
  }
  time.Sleep(time.Millisecond * 200)
}

func (g *Grid) findTraveler(travelerID int) (int, int) {
  for i := 0; i < m; i++ {
    for j := 0; j < n; j++ {
      if g.grid[i][j] == travelerID {
        return i, j
      }
    }
  }
  return -1, -1
}

func (g *Grid) cameraPrint(movesSlice []string) {
  fmt.Println("Aktualne rozmieszczenie podrózników")
  for i := 0; i < m; i++ {
    for j := 0; j < n; j++ {
      fmt.Printf("%d ", g.grid[i][j])
    }
    fmt.Println()
  }
  fmt.Println()

  for _, move := range movesSlice {
    fmt.Printf(move)
  }
}

func main() {
  rand.NewSource(time.Now().UnixNano())
  grid := Grid{}
  grid.initialize() // initialize grid of m x n
  maxGoroutines := 8
  guard := make(chan struct{}, maxGoroutines)
  guard <- struct{}{}
  // var wg sync.WaitGroup
  movesSlice := make([]string, 0)
  travelerAdder := make(chan int)
  travelerMover := make(chan int)
  cameraTicker := time.NewTicker(time.Second * 5)
  moves := make(chan string)

  for i := 0; i < 4; i++ {
    grid.addTraveler()
  }

  for i := 0; i < 2; i++ {
    go func() {
      for {
        moveDelay := rand.Intn(4000)
        time.Sleep(time.Millisecond * time.Duration(moveDelay))
        travelerMover <- moveDelay
      }
    }()
  }

  for i:= 0; i < 2; i++ {
    go func() {
      for {
        addDelay := rand.Intn(3000)
        time.Sleep(time.Millisecond * time.Duration(addDelay))
        travelerAdder <- addDelay
      }
    }()
  }

  go func() {
    for {
      select {
      case msg := <-moves:
        movesSlice = append(movesSlice, msg)
      }
    }
  }()

  for {
    select {
    case msg1 := <-travelerAdder:
      fmt.Println("Traveler added - time", msg1)
      grid.addTraveler()
    case msg := <-travelerMover:
      fmt.Println("Traveler move - time", msg)
      travelerID := grid.travelerIDs[rand.Intn(len(grid.travelerIDs))]
      grid.moveTraveler(travelerID, moves)
    case <-cameraTicker.C:
      grid.cameraPrint(movesSlice)
    }
  }
}