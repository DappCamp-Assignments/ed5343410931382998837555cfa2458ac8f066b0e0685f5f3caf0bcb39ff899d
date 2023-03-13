# Kakuro Assignment

Kakuro is a type of logic puzzle that is often referred to as "cross sums" or "crosswords with numbers." It is played on a grid that is similar to a crossword puzzle, but instead of words, players must fill in the grid with numbers.

The objective of the game is to fill in each *white* square in the grid with a number from 1 to 9, without repeating any numbers within a row or column. In addition, each row and column is associated with a set of clues - these clues indicate the sum of the numbers that must be placed in the row or column. For example, a clue of "6" for a row with three squares means that the numbers placed in those squares must add up to 6. No number should be repeated in a single run.

Players use a combination of deductive reasoning and trial-and-error to solve the puzzle. They start by looking for squares with only one possible solution, and then use those solutions to eliminate possibilities in other squares. As they progress, they may need to use more complex strategies to deduce the correct solution.

You can play a game of kakuro online [here](https://www.kakuros.com/?s=5x5)

Write a program to verify a kakuro solution in form a circom circuit. To make things easier, the scope of this problem has been reduced using the following constraints

1. Number of rows and columns are equal
2. The size of grid will not be greater than 5x5
3. Each row will not have more than one row and column sum clue

## Specifications

-   Your input should be of this form

    ```json
    {
        "rowSums" : [
            [0, 0, 0],
            [1, 2, 11],
            [1, 3, 19],
            [2, 4, 16],
            [3, 4, 17]
        ],
        "columnSums" : [
            [0, 0, 0],
            [1, 2, 17],
            [1, 3, 6],
            [2, 4, 23],
            [3, 4, 17]
        ],
        "solution": [
            [0, 0, 0, 0, 0],
            [0, 8, 3, 0, 0],
            [0, 9, 2, 8, 0],
            [0, 0, 1, 6, 9],
            [0, 0, 0, 9, 8]
        ]
    }

-   Each row of clue in `rowSums` is of the form [`Start Index`, `End Index`, `Sum`]. For example, in the input shared above, the clues mentioned under `rowSums` indicate - 

    * In first row, from start index `0` to end index `0` the sum should be `0`
    * In second row, from start index `1` to end index `2` the sum should be `11` and so on...

-   Each row of clue in `colSums` is of the form [`Start Index`, `End Index`, `Sum`]. For example, in the input shared above, the clues mentioned under `colSums` indicate - 

    * In first column, from start index `0` to end index `0` the sum should be `0`
    * In second column, from start index `1` to end index `2` the sum should be `17` and so on...

-   The solution contains `0` at blocks that shouldn't be filled

-   Given an invalid solution for the given constraints the verification should fail

## Evaluation

-   Clone this repo.

    ```
    git clone CLONE_URL
    ```

-   Create a new branch with your name. You can use the following command

    ```
    git checkout -b my-name
    ```

-  Complete the circuit in [circuits/kakuro.cirom](circuits/kakuro.cirom) file

-  Use this command to run test

    ```
    yarn test
    ```

-   Create a pull request from your branch to the main branch of the repo to run the github workflow
