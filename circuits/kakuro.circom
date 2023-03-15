pragma circom 2.0.3;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";


/* 
    This function will check whether cell contains value other than 1 to 9.
    Returns 1 if value lies between 1 to 9 and 0 otherwise
*/
template IsInRange(n){
    signal input left_value;
    signal input in;
    signal input right_value;
    signal output out;

    component greater_than_equal_to_left = GreaterEqThan(n);
    greater_than_equal_to_left.in[0] <== in;
    greater_than_equal_to_left.in[1] <== left_value;
    greater_than_equal_to_left.out === 1;

    component less_than_equal_to_right = LessEqThan(n);
    less_than_equal_to_right.in[0] <== in;
    less_than_equal_to_right.in[1] <== right_value;
    less_than_equal_to_right.out === 1;

    component and_gate_between_these_two_constraints = AND();
    and_gate_between_these_two_constraints.a <== greater_than_equal_to_left.out;
    and_gate_between_these_two_constraints.b <== less_than_equal_to_right.out;

    out <== and_gate_between_these_two_constraints.out;
}

/*
 * `out` = `cond` ? `L` : `R`
 */
template IfThenElse() {
    signal input cond;
    signal input L;
    signal input R;
    signal output out;

    out <== cond * (L - R) + R;
}



/*  
    Check whether the given cell position is a empty box or a gray box
    returns 1 if it is an empty box, otherwise returns 0
*/

/* template IsEmptyBox(n){ 
    signal input start_index;
    signal input index_of_cell;
    signal input end_index;
    signal output out;

    component is_index_in_range = IsInRange(n);
    is_index_in_range.left_value <== start_index;
    is_index_in_range.in <== index_of_cell;
    is_index_in_range.right_value <== end_index;
    out <== is_index_in_range.out;
} */






template Kakuro(size) {
    signal input rowSums[size][3];
    signal input columnSums[size][3];
    signal input solution[size][size];

    /* signal template_solution[size][size];
    for(var i =0;i<size;i++){
        for(var j =0;j<size;j++){
            if
        }
    } */
    // Check 0 <= size <= 5
    // TODO : How to check number of bits required to store a number so that 
    // we don't need to pass a hardcoded number in the `LessThanEq` circuit
    // It does not seem we can do that currently so marking as a TODO for future task

    // These are not constraints, these are just assumptions that we need to make while implementing this assignment
    /* 
        Number of rows and columns are equal 
        The size of grid will not be greater than 5x5
        Each row will not have more than one row and column sum clue    
    */

    /*
        - NO_NEED: Number of rows and columns are equal - No need to check this as we are passing only one parameter size
        - NO_NEED: No need to check for "Each row will not have more than one row and column sum clue" 
        as we have been provided hardcoded value as 3 -  
    */

    component validate_size = IsInRange(3);
    validate_size.left_value <== 1;
    validate_size.in <== size;
    validate_size.right_value <== 5;
    validate_size.out === 1;

    
    /* 
        Validate cell values
    */
    var i =0;
    var j =0;
    component validate_cell;
    for( i = 0;i<size;i++){
        // var j =0;
        for( j = 0;j<size;j++){

            /* 
                Solution's value must lie between 1 to 9 except gray block indexes
            */
             
            
            /* 
                - Gray block indexes can contain any value as long as they are not counted in the sum but for now - we will assume that it will 
                    always contain 0
            */

            validate_cell = IsInRange(4);
            validate_cell.left_value <== 1;
            validate_cell.in <== solution[i][j];
            validate_cell.right_value <== 9;
            validate_cell.out === 1;
        }   
    }

    /*
        Checking for sum value for row 
    */
    // var i = 0;
    component is_empty_box_checker;
    for (i = 0;i<size;i++){
        var sum_of_row_values = 0;
        // var j =0;
        for(j = 0;j<size;j++){

            is_empty_box_checker = IsInRange(4);
            is_empty_box_checker.left_value <== rowSums[i][0];
            is_empty_box_checker.in <== j;
            is_empty_box_checker.right_value <== rowSums[i][1];
            
            // If the column index is an empty box then it will return 1
            sum_of_row_values += solution[i][j]*is_empty_box_checker.out; 
        }
        sum_of_row_values === rowSums[i][2];
    }

    /*
        Checking for sum value for columns 
    */
    // var j =0;
    for (  j = 0;j<size;j++){
        var sum_of_column_values = 0;
        // var i =0;
        for(  i = 0;i<size;i++){

            is_empty_box_checker = IsInRange(4);
            is_empty_box_checker.left_value <== columnSums[j][0];
            is_empty_box_checker.in <== j;
            is_empty_box_checker.left_value <== columnSums[i][1];
            
            // If the array index is an empty box then it will return 1
            sum_of_column_values += solution[i][j]*is_empty_box_checker.out; 
        }
        sum_of_column_values === columnSums[i][2];
    }
}

component main { public [rowSums, columnSums] } = Kakuro(5);
