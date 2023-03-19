pragma circom 2.0.3;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";

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

template areDistinctNumbers(){
    signal input in[2]; // Takes two numbers
    signal input skip; // Check whether to skip comparing numbers,if yes then return 1 i.e. they are distinct
    signal output out;

    // Constraint on skip i.e. it can be only 0 & 1
    skip*(1-skip) === 0;

    component is_skip_zero = IsZero();
    is_skip_zero.in <== skip;

    // Now checking if two numbers are equal 
    component two_numbers_equal = IsEqual();
    two_numbers_equal.in[0] <== in[0];
    two_numbers_equal.in[1] <== in[1];

    component if_else_executor = IfThenElse();

    if_else_executor.cond <== is_skip_zero.out; // if skip is zero then the output `skip_check.out` should be 1 and hence the 
    // the result should be based on whether the numbers are equal or not. 
    if_else_executor.L <==  1 - two_numbers_equal.out; // If skip is 0 i.e. `skip_check.out` to be 1, and hence return should be  
    // inverse of the answer whether the two numbers are equal or not.
    if_else_executor.R <==  1; // value of `out` when skip will be 1 i.e.`skip_check.out` to be 0, then it does not matter if the 
    // numbers are equal (because skip is set to 1 only when the numbers is zero) or not we will just mark it as they were different
    // and so the answer is 1 always
    out <== if_else_executor.out;
    log("in[0] => ",in[0]);
    log("in[1] => ",in[1]);
    log("skip => ",skip);
    log("++++++++++");
    log("is_skip_zero.out => ",is_skip_zero.out); // when skip is disabled
    log("if_else_executor.L => ",1 - two_numbers_equal.out);
    log("if_else_executor.R => ", if_else_executor.R);
    log("if_else_executor.out => ", if_else_executor.out);
    log("----------");

    
}

template AreNumbersUnique(size){
    signal input numbers[size];
    signal output out;

    component areNumbersDistinct[size][size];
    component isNumberZero[size][size];
    component if_else_checker[size][size];
    component and[size][size];
    // signal xor[size][size];
    /* and[0][0] = AND();
    and[0][0].a <== 1; // if we initialise it with 1 then we will be sure that all numbers are distinct if xor[4][4] is 0
    and[0][0].b <== 1; // dummy data for using and[i][j-1] */
    component isIzero[size];
    component isIzero_if_else[size];

    signal distinct_numbers_output[size][size];
    component multiand[size];
    signal multi_and_output_storage_variable[size];
    component if_else_for_j_not_equal_to_i[size][size];
    // [0, 8, 8, 0, 0]
    for(var i=0;i<size;i++){
        distinct_numbers_output[i][i] <== 1;
        for(var j=i+1;j<size;j++){

            /*
                We have to make sure that the number is not zero, if it is zero then we have to ignore the isEqual() 
                constraint. 
            */
            isNumberZero[i][j] = IsZero();
            isNumberZero[i][j].in <== numbers[j];
            
            log("when i => ",i," and j => ",j);
            areNumbersDistinct[i][j] = areDistinctNumbers();
            areNumbersDistinct[i][j].in[0] <== numbers[i];
            areNumbersDistinct[i][j].in[1] <== numbers[j];
            areNumbersDistinct[i][j].skip <== isNumberZero[i][j].out; // If the number numbers[j] is zero then out will be 1 


            distinct_numbers_output[i][j] <== areNumbersDistinct[i][j].out;
            distinct_numbers_output[j][i] <== areNumbersDistinct[i][j].out;
        }
        multiand[i] = MultiAND(size);
        for(var k =0;k<size;k++){
            multiand[i].in[k] <== distinct_numbers_output[i][k];
        }
        multi_and_output_storage_variable[i] <== multiand[i].out;
    }
    component multi_of_multi = MultiAND(size);
    multi_of_multi.in <== multi_and_output_storage_variable;
    out <== multi_of_multi.out; // if the xor is zero that means either all the numbers were equal or all the numbers different

}


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

    out <== greater_than_equal_to_lower.out * less_than_equal_to_upper.out;
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
    component is_rowsum_equal[size];
    component are_numbers_unique_rows[size];

    signal sub_row_array[size][size];
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
            sub_row_array[i][j] <== solution[i][j];
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
        is_rowsum_equal[i] = IsEqual();
        is_rowsum_equal[i].in[0] <== sum_of_row_values;
        is_rowsum_equal[i].in[1] <== rowSums[i][2];

        are_numbers_unique_rows[i] = AreNumbersUnique(size);
        are_numbers_unique_rows[i].numbers <== sub_row_array[i];
        are_numbers_unique_rows[i].out === 1;
        // log("This constraint sum_of_row_values === rowSums[i][2] is valid here ", sum_of_row_values == rowSums[i][2]);
    }

    component is_empty_box_checker_for_columns[size][size];
    signal value_contribution_to_columnsum_from_that_index[size][size];
    component is_columnsum_equal[size];

    component are_numbers_unique_column[size];
    signal sub_column_array[size][size];

    for (var j = 0;j<size;j++){
        var sum_of_column_values = 0;
        for(var i = 0;i<size;i++){

            is_empty_box_checker_for_columns[i][j] = IsInRange(4);
            is_empty_box_checker_for_columns[i][j].lower_value <== columnSums[j][0];
            is_empty_box_checker_for_columns[i][j].in <== i;
            is_empty_box_checker_for_columns[i][j].upper_value <== columnSums[j][1];
            
            value_contribution_to_columnsum_from_that_index[i][j] <== solution[i][j]*is_empty_box_checker_for_columns[i][j].out; 
            // log("For column j = ",j," and row i= ",i," This constraint value_contribution_to_columnsum_from_that_index[",i,"][",j,"] has value = ",value_contribution_to_columnsum_from_that_index[i][j]);
            sub_column_array[j][i] <== solution[i][j];
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
        is_columnsum_equal[j] = IsEqual();
        is_columnsum_equal[j].in[0] <== sum_of_column_values;
        is_columnsum_equal[j].in[1] <== columnSums[j][2];
        
        are_numbers_unique_column[j] = AreNumbersUnique(size);
        are_numbers_unique_column[j].numbers <== sub_column_array[j];
        are_numbers_unique_column[j].out === 1;
        // log("This constraint sum_of_column_values === columnSums[j][2] is valid here ", sum_of_column_values == columnSums[j][2]);
    }
}

component main { public [rowSums, columnSums] } = Kakuro(5);
