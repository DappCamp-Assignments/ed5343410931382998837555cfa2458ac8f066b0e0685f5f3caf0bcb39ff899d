pragma circom 2.0.3;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";


/* 
    This function will check whether cell contains value other than 1 to 9.
    Returns 1 if value lies between 1 to 9 and 0 otherwise
*/
template IsInRange(n){
    signal input lower_value;
    signal input in;
    signal input upper_value;
    signal output out;

    component greater_than_equal_to_lower = GreaterEqThan(n);
    greater_than_equal_to_lower.in[0] <== in;
    greater_than_equal_to_lower.in[1] <== lower_value;

    component less_than_equal_to_upper = LessEqThan(n);
    less_than_equal_to_upper.in[0] <== in;
    less_than_equal_to_upper.in[1] <== upper_value;

    out <== greater_than_equal_to_lower.out*less_than_equal_to_upper.out;
}

template Kakuro(size) {
    signal input rowSums[size][3];
    signal input columnSums[size][3];
    signal input solution[size][size];
    signal output out;
    
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
    validate_size.lower_value <== 1;
    validate_size.in <== size;
    validate_size.upper_value <== 5;
    validate_size.out === 1;
    // log("This constraint validate_size.out is valid and has value = ",validate_size.out);
    /* 
        If a box index lies outside the index start_index & end_index, then 
        it is a gray box
    */
    component is_gray_box[size][size];

    /* 
        Validate cell values i.e. the cell value should lie between 1 and 9 (both inclusive)
    */
    component validate_cell[size][size];
    for(var i = 0;i<size;i++){
        for(var j = 0;j<size;j++){

            /*
                Check whether it is a gray box  
            */
            is_gray_box[i][j] = IsZero(); // Since these values can be other values as well. we might want to 
            is_gray_box[i][j].in <== solution[i][j];
            

            validate_cell[i][j] = IsInRange(4);
            validate_cell[i][j].lower_value <== 1;
            validate_cell[i][j].in <== solution[i][j];
            validate_cell[i][j].upper_value <== 9;
            /*
                If it is a gray box then   validate_cell[i][j].out will be 0 and is_gray_box[i][j].out will be 1 
                and so the following constraint must suffice
            */
            validate_cell[i][j].out === 1-is_gray_box[i][j].out;
            // log("For row i = ",i," and column j= ",j," This constraint validate_cell[",i,"][",j,"].out has value = ",validate_cell[i][j].out);
        }   
    }

    /*
        Validating for sum value for row 
    */
    component is_empty_box_checker[size][size];
    signal value_contribution_to_rowsum_from_that_index[size][size];
    for (var i = 0;i<size;i++){
        var sum_of_row_values = 0;
        for(var j = 0;j<size;j++){

            is_empty_box_checker[i][j] = IsInRange(4);
            is_empty_box_checker[i][j].lower_value <== rowSums[i][0];
            is_empty_box_checker[i][j].in <== j;
            is_empty_box_checker[i][j].upper_value <== rowSums[i][1];
            
            /*
                If it is an empty box ( not gray box ) containing valid value then is_empty_box_checker[i][j].out 
                will be 1 and so the rowsum will add that cell value into the sum variable `sum_of_row_values`
            */
            value_contribution_to_rowsum_from_that_index[i][j] <== solution[i][j]*is_empty_box_checker[i][j].out; 
            // log("For i = ",i," and j= ",j," This constraint value_contribution_to_rowsum_from_that_index[",i,"][",j,"] has value = ",value_contribution_to_rowsum_from_that_index[i][j]);
        }
        /*
            Calculation of the sum of the values for the row `i`
        */
        for(var k=0;k<size;k++){
            sum_of_row_values += value_contribution_to_rowsum_from_that_index[i][k];
        }
        // log("For row i = ",i," This signal sum_of_row_values has value = ",sum_of_row_values);
        /*
            Calculated sum should be equal to the sum provided for that row
        */
        sum_of_row_values === rowSums[i][2];
        // log("This constraint sum_of_row_values === rowSums[i][2] is valid here ", sum_of_row_values == rowSums[i][2]);
    }

    component is_empty_box_checker_for_columns[size][size];
    signal value_contribution_to_columnsum_from_that_index[size][size];
    for (var j = 0;j<size;j++){
        var sum_of_column_values = 0;
        for(var i = 0;i<size;i++){

            is_empty_box_checker_for_columns[i][j] = IsInRange(4);
            is_empty_box_checker_for_columns[i][j].lower_value <== columnSums[j][0];
            is_empty_box_checker_for_columns[i][j].in <== i;
            is_empty_box_checker_for_columns[i][j].upper_value <== columnSums[j][1];
            
            value_contribution_to_columnsum_from_that_index[i][j] <== solution[i][j]*is_empty_box_checker_for_columns[i][j].out; 
            // log("For column j = ",j," and row i= ",i," This constraint value_contribution_to_columnsum_from_that_index[",i,"][",j,"] has value = ",value_contribution_to_columnsum_from_that_index[i][j]);
        }
        /*
            Calculation of the sum of the values for the column `j`
        */
        for(var k=0;k<size;k++){
            sum_of_column_values += value_contribution_to_columnsum_from_that_index[k][j];
        }
        // log("For column j = ",j," This signal sum_of_column_values has value = ",sum_of_column_values);
        /*
            Calculated sum should be equal to the sum provided for that column
        */
        sum_of_column_values === columnSums[j][2];
        // log("This constraint sum_of_column_values === columnSums[j][2] is valid here ", sum_of_column_values == columnSums[j][2]);
    }
}

component main { public [rowSums, columnSums] } = Kakuro(5);
