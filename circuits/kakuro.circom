pragma circom 2.1.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/switcher.circom";

template IfThenElse() {
    signal input cond;
    signal input L;
    signal input R;
    signal output out;

    out <== cond * (L - R) + R;
}
/*
    It takes two numbers `in[0]` , `in[1]` and a parameter `skip` which when set to 1, skips checking the numbers
    Returns 1 if the numbers are distinct or skip is set to 1, 0 otherwise
*/
template AreDistinctNumbers(){
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

    /* component if_else_executor = IfThenElse();

    if_else_executor.cond <== is_skip_zero.out; // if skip is zero then the output `skip_check.out` should be 1 and hence the 
    // the result should be based on whether the numbers are equal or not. 
    if_else_executor.L <==  1 - two_numbers_equal.out; // If skip is 0 i.e. `skip_check.out` to be 1, and hence return should be  
    // inverse of the answer whether the two numbers are equal or not.
    if_else_executor.R <==  1; // value of `out` when skip will be 1 i.e.`skip_check.out` to be 0, then it does not matter if the 
    // numbers are equal (because skip is set to 1 only when the numbers is zero) or not we will just mark it as they were different
    // and so the answer is 1 always
    out <== if_else_executor.out; */

    component switcher = Switcher();
    switcher.sel <== is_skip_zero.out;
    switcher.L <== 1 - two_numbers_equal.out;
    switcher.R <== 1;
    out <== switcher.outR;
}

/*  
    Given a list it returns 1 if all the numbers in the list are unique ( or 0), 0 otherwise
*/
template AreNumbersUnique(size){
    signal input numbers[size];
    signal output out;

    component areNumbersDistinct[size][size];
    component isNumberZero[size][size];

    signal distinct_numbers_output[size][size];
    component multiand[size];
    signal multi_and_output_storage_variable[size];
    for(var i=0;i<size;i++){
        distinct_numbers_output[i][i] <== 1;
        for(var j=i+1;j<size;j++){

            /*
                We have to make sure that the number is not zero, if it is zero then we have to ignore the isEqual() 
                constraint. 
            */
            isNumberZero[i][j] = IsZero();
            isNumberZero[i][j].in <== numbers[j];
            
            areNumbersDistinct[i][j] = AreDistinctNumbers();
            areNumbersDistinct[i][j].in[0] <== numbers[i];
            areNumbersDistinct[i][j].in[1] <== numbers[j];

            // If the number numbers[j] is zero then out should be 1 
            areNumbersDistinct[i][j].skip <== isNumberZero[i][j].out; 


            distinct_numbers_output[i][j] <== areNumbersDistinct[i][j].out;
            distinct_numbers_output[j][i] <== areNumbersDistinct[i][j].out;
        }
        multiand[i] = MultiAND(size);
        for(var k =0;k<size;k++){
            multiand[i].in[k] <== distinct_numbers_output[i][k];
        }
        multi_and_output_storage_variable[i] <== multiand[i].out;
    }
    component multi_and_of_multi_and = MultiAND(size);
    multi_and_of_multi_and.in <== multi_and_output_storage_variable;
    out <== multi_and_of_multi_and.out; // if the AND is zero that means some of the numbers were equal

}


/* 
    This circuit will check whether cell contains value other than 1 to 9.
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

/* 
    This circuit will check whether sum of cell values contain valid sum as constrained by the input
    Returns 1 if sum of the filled solution cells is equal to the sum constrained by the input in a given row/column of array
*/
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
/* 
    This circuit will check whether all cells have valid numbers or not
    Returns 1 all the cells of the row have valid elements
*/
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

        validation_status[i].out === 1;
    }
    /* component multi_and = MultiAND(size);
    multi_and.in <== validation_status_result;
    out <==  multi_and.out; */
    out <== 1;
}
/*  
    This circuit will use the circuit `RowCellsContainsValidValue` repeatedly on each row and check for invalid cells.
    Returns 1 if no solution cell has invalid cell
*/
template WholeCellContainsValidValue(size,n){
    signal input whole_data[size][size];
    signal output out;

    component one_row_validation[size];
    /* signal result_of_one_row_validation[size]; */
    for (var i =0;i<size;i++){
        one_row_validation[i] = RowCellsContainsValidValue(size,n);
        for(var k=0;k<size;k++){
            one_row_validation[i].numbers[k] <== whole_data[i][k];
        }
        one_row_validation[i].out === 1;
    }
    /* component multi_and = MultiAND(n);
    multi_and.in <== result_of_one_row_validation;
    out <== multi_and.out; */
    out <== 1;
}

template Kakuro(size) {
    signal input rowSums[size][3];
    signal input columnSums[size][3];
    signal input solution[size][size];
    signal output out;

    /*
        Checking whether the size is between 1 and 5 only, It is not a constraint though 
    */
    component validate_size = IsInRange(3);
    validate_size.lower_value <== 1;
    validate_size.in <== size;
    validate_size.upper_value <== 5;
    validate_size.out === 1;

    /* 
        Validate cell values i.e. the cell value should lie between 1 and 9 (both inclusive)
    */
    component validate_cells = WholeCellContainsValidValue(size,5);
    validate_cells.whole_data <== solution;
    validate_cells.out === 1;
    /*
        Validating for sum value for row 
    */

    component is_valid_sum_across_row[size];
    var one_row_at_a_time[size];
    /* signal results_of_sum_constraints_on_row[size]; */
    for(var i=0;i<size;i++){
        for(var j=0;j<size;j++){
            one_row_at_a_time[j] = solution[i][j];
        }
        is_valid_sum_across_row[i] = ValidSum(size);
        is_valid_sum_across_row[i].numbers <== one_row_at_a_time;
        is_valid_sum_across_row[i].sumConstraint <== rowSums[i];
        is_valid_sum_across_row[i].out === 1;
        /* results_of_sum_constraints_on_row[i] <== is_valid_sum_across_row[i].out; */
    }
    /* component multi_and_on_row = MultiAND(5);
    multi_and_on_row.in <== results_of_sum_constraints_on_row;
    multi_and_on_row.out === 1; */

    component is_valid_sum_across_columns[size];
    var one_column_at_a_time[size];
    /* signal results_of_sum_constraints_on_column[size]; */
    for(var j=0;j<size;j++){
        for(var i=0;i<size;i++){
            one_column_at_a_time[i] = solution[i][j];
        }
        is_valid_sum_across_columns[j] = ValidSum(size);
        is_valid_sum_across_columns[j].numbers <== one_column_at_a_time;
        is_valid_sum_across_columns[j].sumConstraint <== columnSums[j];
        is_valid_sum_across_columns[j].out === 1;
        /* results_of_sum_constraints_on_column[j] <== is_valid_sum_across_columns[j].out; */
    }
    /* component multi_and_on_column = MultiAND(5);
    multi_and_on_column.in <== results_of_sum_constraints_on_column;
    multi_and_on_row.out === 1; */

    /* signal valid_sum_across_row_and_column <== multi_and_on_row.out * multi_and_on_column.out;
    out <== validate_cells.out * valid_sum_across_row_and_column;
    out === 1; */
    
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