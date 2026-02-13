# tic-tac-no

## Summary
This challenge provides a Linux CLI program with an out-of-bounds write vulnerability that allows the user to modify variables.

Artifacts:
- `chall/chall`: vulnerable executable program provided by the challenge authors
- `chall/chall.c`:  vulnerable program source code provided by challenge authors

## Context 

The challenge has a provided domain and port, but it can also be run locally using the provided executable. The program intends to be an unbeatable AI by making the most optimal move each time.

Upon running, the program starts a game of tic-tac-toe, prompting the user to enter a row and column for their move.

```
You want the flag? You'll have to beat me first!
   |   |   
---|---|---
   |   |   
---|---|---
   |   |   

Enter row #(1-3): 
```

## Vulnerability
The `chall` program contains an out-of-bounds write vulnerability due to an improper check of the index within the `playerMove()` function.

```
void playerMove() {
   int x, y;
   do{
      printf("Enter row #(1-3): ");
      scanf("%d", &x);
      printf("Enter column #(1-3): ");
      scanf("%d", &y);
      int index = (x-1)*3+(y-1);
      if(index >= 0 && index < 9 && board[index] != ' '){
         printf("Invalid move.\n");
      }else{
         board[index] = player; // Should be safe, given that the user cannot overwrite tiles on the board
         break;
      }
   }while(1);
}
```

The program checks whether the index is within bounds and whether the selected tile is already occupied before rejecting the move. However, it doesn't properly handle invalid indices. 

Consider an invalid `x` and `y` input such that `index` becomes negative. This would prompt the code to execute the `else` branch, writing to `board[index]` even though the input values are invalid. As a result, `board[index]` may reference memory outside the intended buffer bounds.

By modifying the `computer` variable to be `X`, we can make the computer write `X` instead of `O`, allowing us to win the game.

## Exploitation
The exploit involves inputting an invalid row and column to get an index outside the buffer bounds to write to an address of our choice.

Using `Binary Ninja`, we can calculate the offset between the addresses of the `board` buffer and the `computer` variable.

![screenshot](./tic-tac-no_binaryninja.png)

From the screenshot, we can see that `board` is located at `0x00404068` and `computer` is located at `0x00404051`. By taking the difference between these two addresses, we can calculate the offset between the variables, which turns out to be `-0x17` (-23 in decimal).

Using the index calculation `index = (x - 1) * 3 + (y - 1)` from `playerMove()` above, we can input values for `x` and `y` such that `index` results in `-23`. One example of such input would be `x = -5` and `y = -4`.

By doing so, we write to the address `board[-23]`, or at the location of the variable `computer`, overwriting it to 'X'.

```
Enter row #(1-3): -5
Enter column #(1-3): -4

   |   |   
---|---|---
   | X |   
---|---|---
   |   |   
```

After entering these inputs, the computer writes `X` instead of `O`, confirming that the `computer` variable was successfully overwritten. By continuing this game, both the user and the computer will be playing `X`, leading to a guaranteed win.

## Remediation
The program should validate user input rather than relying solely on the calculated index value. It can instead check that `row` and `column` are within the range [1, 3].