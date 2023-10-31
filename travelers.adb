with Ada.Numerics.Float_Random;
with Ada.Text_IO;
with Ada.Calendar;
with Ada.Containers.Vectors;
with Ada.Numerics.Discrete_Random;
with Ada.Task_Identification;
with Ada.Task_Attributes;
use Ada.Calendar;
use Ada.Text_IO;
use Ada.Numerics.Float_Random;

procedure Travelers is
  M : Integer := 5;
  N : Integer := 5;  
  K : Integer := 12;
  Gen : Ada.Numerics.Float_Random.Generator;
  index : Integer := 1;

  --  type Arr_Matrix is array (Positive range <>, Positive range <>) of Integer;
  type Arr_Travelers_ID is array (Positive range <>) of Integer;
  type Int_Type is array (Integer range <>) of Integer;

  type Coordinate is record 
    X : Integer;
    Y : Integer;
  end record;

  package Int_Vectors is new Ada.Containers.Vectors
    (Index_Type => Natural, Element_Type => Integer);

  use Int_Vectors;
  --  package Grid_Package is
  --    type Grid is record
  --      Grid_Matrix : Arr_Matrix(1 .. M, 1 .. N);
  --      Travelers: Integer;
  --      Traveler_IDs: Int_Vectors.Vector;
  --      --  Traveler_IDs : Arr_Travelers_ID(1 .. M * N - 1);
  --    end record;
  --  end Grid_Package;

  package Grid_Package is
    --  type Grid is private;
    type Arr_Matrix is array (Positive range <>, Positive range <>) of Integer;
    type Grid is record
      Grid_Matrix : Arr_Matrix(1 .. M, 1 .. N);
      Travelers: Integer;
      Traveler_IDs: Int_Vectors.Vector;
    end record;

    protected Grid_Protected is
      procedure Add_Traveler(G: in out Grid);
      procedure Move_Traveler(G: in out Grid; Traveler_ID: Integer);
      procedure Initialize(G : in out Grid);
    end Grid_Protected;

    procedure Initialize(G : in out Grid);
    procedure Add_Traveler(G : in out Grid);
    procedure Move_Traveler(G : in out Grid; Traveler_ID : Integer);
  end Grid_Package;

  function Random_Int(n : Integer; Gen : in out Ada.Numerics.Float_Random.Generator) return Integer is
    Result : Integer;
    Rnd : Float;
  begin
    Ada.Numerics.Float_Random.Reset(Gen);
    Rnd := Ada.Numerics.Float_Random.Random(Gen);
    if Rnd < 0.0 then
      Rnd := 0.0;
    elsif Rnd > 1.0 then
      Rnd := 1.0;
    end if;
    Result := 1 + Integer(Float(n - 1) * Rnd);
    return Result;
  end Random_Int;

  function Is_Blank(G : in out Grid_Package.Grid; X : Integer; Y : Integer) return Boolean is
  begin 
    if X < 1 or else Y < 1 or else X > M or else Y > N then
      return False;
    end if;
    return G.Grid_Matrix(X, Y) = 0;
  end Is_Blank;

  package body Grid_Package is

    protected body Grid_Protected is 

      procedure Add_Traveler(G : in out Grid) is
        Row : Integer;
        Column : Integer;
        Traveler_ID : Integer;
      begin 
        if G.Travelers >= M * N then
          return;
        end if;
        Row := Random_Int(M, Gen);
        Column := Random_Int(N, Gen);
        if Is_Blank(G, Row, Column) then
          Traveler_ID := G.Travelers + 1;
          G.Grid_Matrix(Row, Column) := Traveler_ID;
          Int_Vectors.Append(G.Traveler_IDs, Traveler_ID);
          index := index + 1;
          Put_Line("Nowy podróżnik" & Integer'Image(Traveler_ID) & " pojawił się w wierzchołku ("&Integer'Image(Row) & "," & Integer'Image(Column) & ")");
          G.Travelers := G.Travelers + 1;
        end if;
        if G.Travelers >= M * N then
          return;
        end if;
        --  delay 0.15;
      end Add_Traveler;

      procedure Move_Traveler(G: in out Grid; Traveler_ID: Integer) is
        Current_Row, Current_Column : Integer;
        Neighbours : array(1 .. 4) of Coordinate;
        Available_Directions : array(1 .. 4) of Coordinate;
        randomCoordinate : Coordinate;
        rand_num : Float;
        Num_Available_Directions : Integer := 0;

        procedure Find_Traveler(Traveler_ID : Integer) is
        begin
          for I in 1 .. M loop
            for J in 1 .. N loop
              if G.Grid_Matrix(I, J) = Traveler_ID then
                Current_Row := I;
                Current_Column := J;
                return;
              end if;
            end loop;
          end loop;
        end Find_Traveler;

      begin
        --  Put_Line("Odebrano travelerID o val " & Integer'Image(Traveler_ID));
        Ada.Numerics.Float_Random.Reset(Gen);
        --  Inicjalizacja tablicy sąsiadow
        --  Zainicjowanie currentRow i currentCol na odpowiednie wartości
        Find_Traveler(Traveler_ID); 
        Neighbours(1) := (Current_Row - 1, Current_Column);
        Neighbours(2) := (Current_Row + 1, Current_Column);
        Neighbours(3) := (Current_Row, Current_Column + 1);
        Neighbours(4) := (Current_Row, Current_Column - 1);

        declare 
          newRow : Integer;
          newColumn : Integer;
        begin 
          for I in 1 .. Neighbours'Length loop
            --  Jezeli pole jest puste, zwiekszenie liczby mozliwych kierunkow, zapisanie wspolrzednych sasiada
            if Is_Blank(G, Neighbours(I).X, Neighbours(I).Y) then
              Num_Available_Directions := Num_Available_Directions + 1;
              Available_Directions(Num_Available_Directions) := (Neighbours(I).X, Neighbours(I).Y);
            end if;
          end loop;

          if Num_Available_Directions > 0 then 
            rand_num := Ada.Numerics.Float_Random.Random(Gen);
            randomCoordinate := Available_Directions(1 + Integer(Float(Num_Available_Directions - 1) * rand_num));
            --  Zapisanie wspolrzednych nowo wylosowanego wierzcholka
            newRow := randomCoordinate.X;
            newColumn := randomCoordinate.Y;
            --  Przejscie podroznika na nowa pozycje w gridzie
            G.Grid_Matrix(newRow, newColumn) := Traveler_ID;
            G.Grid_Matrix(Current_Row, Current_Column) := 0; -- reset position
            Put("Podroznik");
            Put(Integer'Image(Traveler_ID));
            Put(" przeszedł z wierzchołka (");
            Put(Integer'Image(Current_Row));
            Ada.Text_IO.Put(", ");
            Ada.Text_IO.Put(Integer'Image(Current_Column));
            Ada.Text_IO.Put(") do wierzchołka (");
            Ada.Text_IO.Put(Integer'Image(newRow));
            Ada.Text_IO.Put(", ");
            Ada.Text_IO.Put(Integer'Image(newColumn));
            Ada.Text_IO.Put(")");
            Ada.Text_IO.Put_Line("");
          end if;
        end;
      end Move_Traveler;

      procedure Initialize(G : in out Grid) is
      begin 
        for Row in G.Grid_Matrix'Range(1) loop
          for Col in G.Grid_Matrix'Range(2) loop
            G.Grid_Matrix(Row, Col) := 0;
          end loop;
        end loop;
        G.Travelers := 0;
      end Initialize;
  
    end Grid_Protected;

    procedure Initialize(G : in out Grid) is
    begin
      Grid_Protected.Initialize(G);
    end Initialize;

    procedure Add_Traveler(G : in out Grid) is
    begin
      Grid_Protected.Add_Traveler(G);
    end Add_Traveler; 

    procedure Move_Traveler(G : in out Grid; Traveler_ID : Integer) is
    begin
      Grid_Protected.Move_Traveler(G, Traveler_ID);
    end Move_Traveler;

  end Grid_Package;

  G : Grid_Package.Grid;

  task type Traveler_Adder is
    entry Go;
  end Traveler_Adder;

  type TASK_ADDER_ACCESS is access Traveler_Adder;

  V_TASK_A1, V_TASK_A2 : TASK_ADDER_ACCESS;

  task type Traveler_Mover is
    entry Go;
  end Traveler_Mover;

  type TASK_MOVER_ACCESS is access Traveler_Mover;

  V_TASK_M1, V_TASK_M2 : TASK_MOVER_ACCESS;

  --  task Ticker;

  --  task body Ticker is
  --    next_tick : Time;
  --    enabled : Boolean := False;
  --  begin 
  --    next_tick := Clock + 6.0;
  --    loop
  --      Put_Line("Aktualny stan tablicy: ");
  --      for Row in G.Grid_Matrix'Range(1) loop
  --        for Col in G.Grid_Matrix'Range(2) loop
  --          Put(Integer'Image(G.Grid_Matrix(Row, Col)) & " ");
  --        end loop;
  --        New_Line;
  --      end loop;

  --      delay until next_tick;
  --      next_tick := next_tick + 6.0;
  --    end loop;
  --  end Ticker;

  --  Task for adding new traveler
  task body Traveler_Adder is
    time : Integer;
    Rnd : Float;
  begin
    Ada.Numerics.Float_Random.Reset(Gen); 
    loop
      select 
        accept Go do 
          Put_Line("Trying to add traveler...");
          Rnd := Ada.Numerics.Float_Random.Random(Gen);
          time := Integer(Float(1750) * Rnd);
          --  Put_Line("Time from Add is " & Integer'Image(time));
          --  Add_Traveler(G);
          Grid_Package.Add_Traveler(G);
          delay 0.001 * Duration(time);
        end Go;
      end select;
    end loop;
  end Traveler_Adder;
  
  --  Task for moving a traveler
  task body Traveler_Mover is
    time : Integer;
    Rnd : Float;
    travelerID : Integer;
    rangeOfIds : Integer;
  begin
    Ada.Numerics.Float_Random.Reset(Gen);
    loop
      select 
        accept Go do 
          Put_Line("Trying to move traveler...");
          Rnd := Ada.Numerics.Float_Random.Random(Gen);
          --  Put_Line(Float'Image(Rnd));
          time := Integer(Float(2500) * Rnd);
          -- Przemieszczanie podroznika  
          rangeOfIds := Integer(G.Traveler_IDs.Length);
          index := 1 + Integer(Rnd * Float(rangeOfIds - 1));
          --  Put_Line(Integer'Image(index) & " index val");
          travelerID := G.Traveler_IDs(index);
          --  Move_Traveler(G, travelerID);
          Grid_Package.Move_Traveler(G, travelerID);
          delay 0.001 * Duration(time);
        end Go;
      end select;
    end loop;
  end Traveler_Mover;

begin
  --  Initialize(G);
  Grid_Package.Initialize(G);

  V_TASK_A1 := new Traveler_Adder;
  V_TASK_A2 := new Traveler_Adder;
  --  V_TASK_A3 := new Traveler_Adder;
  V_TASK_M1 := new Traveler_Mover;
  V_TASK_M2 := new Traveler_Mover;
  --  V_TASK_M3 := new Traveler_Mover;
  --  V_TASK1 := new Traveler_Adder;
  --  V_TASK2 := new Traveler_Adder;
  --  V_TASK_M1 := new Traveler_Mover;
  --  V_TASK_M2 := new Traveler_Mover;

  for I in 1 .. 6 loop 
    --  Add_Traveler(G);
    Grid_Package.Add_Traveler(G);
  end loop;

  --  Ticker.Start;

  --  nieskończona pętla
  loop
    --  Ticker.Start;
    --  Ticker;
    V_TASK_A1.Go;
    V_TASK_A2.Go;
    V_TASK_M1.Go;
    V_TASK_M2.Go;
    --  V_TASK_M2.Go;
    --  Traveler_Mover.Go;
    --  Traveler_Adder.Go;
  end loop;
end Travelers;