pragma circom 2.1.4;

include "circomlib/comparators.circom";
include "circomlib/gates.circom";

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
    /* log("in[0] => ",in[0]);
    log("in[1] => ",in[1]);
    log("skip => ",skip);
    log("++++++++++");
    log("is_skip_zero.out => ",is_skip_zero.out); // when skip is disabled
    log("if_else_executor.L => ",1 - two_numbers_equal.out);
    log("if_else_executor.R => ", if_else_executor.R);
    log("if_else_executor.out => ", if_else_executor.out);
    log("----------"); */

    
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
            
            // log("when i => ",i," and j => ",j);
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

template RowCellsContainsValidValue(size,n){
    signal input numbers[size];
    signal output out;

    component is_gray_box[size];
    component validate_cell[size];
    component validation_status[size];
    signal validation_status_result[size];
    for(var i =0;i<size;i++){
        is_gray_box[i] = IsZero(); 
        is_gray_box[i].in <== numbers[i];
        

        validate_cell[i] = IsInRange(n);
        validate_cell[i].lower_value <== 1;
        validate_cell[i].in <== numbers[i];
        validate_cell[i].upper_value <== 9;

        validation_status[i] = OR();
        validation_status[i].a <== is_gray_box[i].out;
        validation_status[i].b <== validate_cell[i].out;

        validation_status_result[i] <== validation_status[i].out;
    }
    component multi_and = MultiAND(size);
    multi_and.in <== validation_status_result;
    out <==  multi_and.out;
}


template ValidSum (size) {
    signal input numbers[size];
    signal input sumConstraint[3];
    signal output out;

    component is_number_within_range[size];
    signal contribution_to_sum_from_ith_cell[size];

    for(var i =0;i<size;i++){
        
        is_number_within_range[i] = IsInRange(4);
        is_number_within_range[i].lower_value <== 1;
        is_number_within_range[i].in <== numbers[i];
        is_number_within_range[i].upper_value <== 9;
        
        contribution_to_sum_from_ith_cell[i] <== is_number_within_range[i].out * numbers[i];
    }

    var sum =0;
    for(var i=0;i<size;i++){
        sum+=contribution_to_sum_from_ith_cell[i];
    }
    component is_sum_equal = IsEqual();
    is_sum_equal.in[0] <== sum;
    is_sum_equal.in[1] <== sumConstraint[2];

    component are_numbers_unique = AreNumbersUnique(size);
    are_numbers_unique.numbers <== numbers;

    out <== is_sum_equal.out * are_numbers_unique.out;
}

template WholeCellContainsValidValue(size,n){
    signal input whole_data[size][size];
    signal output out;

    component one_row_validation[size];
    signal result_of_one_row_validation[size];
    for (var i =0;i<size;i++){
        one_row_validation[i] = RowCellsContainsValidValue(size,n);
        for(var k=0;k<size;k++){
            one_row_validation[i].numbers[k] <== whole_data[i][k];
        }
        result_of_one_row_validation[i] <== one_row_validation[i].out;
    }
    component multi_and = MultiAND(n);
    multi_and.in <== result_of_one_row_validation;
    out <== multi_and.out;
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
    component validate_cells = WholeCellContainsValidValue(size,5);// 5 if you wish to enter number greater than 15
    validate_cells.whole_data <== solution;
    // log("validate_cell.out ", validate_cells.out);

    /*
        Validating for sum value for row 
    */

    component is_valid_sum_across_row[size];
    var one_row_at_a_time[size];
    signal results_of_sum_constraints_on_row[size];
    for(var i=0;i<size;i++){
        for(var j=0;j<size;j++){
            one_row_at_a_time[j] = solution[i][j];
        }
        is_valid_sum_across_row[i] = ValidSum(size);
        is_valid_sum_across_row[i].numbers <== one_row_at_a_time;
        is_valid_sum_across_row[i].sumConstraint <== rowSums[i];
        results_of_sum_constraints_on_row[i] <== is_valid_sum_across_row[i].out;
    }
    component multi_and_on_row = MultiAND(5);
    multi_and_on_row.in <== results_of_sum_constraints_on_row;


    component is_valid_sum_across_columns[size];
    var one_column_at_a_time[size];
    signal results_of_sum_constraints_on_column[size];
    for(var j=0;j<size;j++){
        for(var i=0;i<size;i++){
            one_column_at_a_time[i] = solution[i][j];
        }
        is_valid_sum_across_columns[j] = ValidSum(size);
        is_valid_sum_across_columns[j].numbers <== one_column_at_a_time;
        is_valid_sum_across_columns[j].sumConstraint <== columnSums[j];
        results_of_sum_constraints_on_column[j] <== is_valid_sum_across_columns[j].out;
    }
    component multi_and_on_column = MultiAND(5);
    multi_and_on_column.in <== results_of_sum_constraints_on_column;

    signal valid_across_row_and_column <== multi_and_on_row.out * multi_and_on_column.out;

    out <== validate_cells.out * valid_across_row_and_column;
}

component main { public [rowSums, columnSums,solution] } = Kakuro(5);

/* INPUT = {
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
  } */