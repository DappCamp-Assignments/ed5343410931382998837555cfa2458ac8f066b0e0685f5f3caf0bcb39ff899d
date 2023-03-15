pragma circom 2.0.3;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";



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
    
    component validate_size = IsInRange(3);
    validate_size.lower_value <== 1;
    validate_size.in <== size;
    validate_size.upper_value <== 5;
    validate_size.out === 1;

    component is_gray_box[size][size];
    component validate_cell[size][size];
    for(var i = 0;i<size;i++){
        for(var j = 0;j<size;j++){

            is_gray_box[i][j] = IsZero(); // Since these values can be other values as well. we might want to 
            is_gray_box[i][j].in <== solution[i][j];
            

            validate_cell[i][j] = IsInRange(4);
            validate_cell[i][j].lower_value <== 1;
            validate_cell[i][j].in <== solution[i][j];
            validate_cell[i][j].upper_value <== 9;
            validate_cell[i][j].out === 1-is_gray_box[i][j].out;
        }   
    }


    component is_empty_box_checker[size][size];
    signal value_contribution_to_rowsum_from_that_index[size][size];
    for (var i = 0;i<size;i++){
        var sum_of_row_values = 0;
        for(var j = 0;j<size;j++){

            is_empty_box_checker[i][j] = IsInRange(4);
            is_empty_box_checker[i][j].lower_value <== rowSums[i][0];
            is_empty_box_checker[i][j].in <== j;
            is_empty_box_checker[i][j].upper_value <== rowSums[i][1];
            
            value_contribution_to_rowsum_from_that_index[i][j] <== solution[i][j]*is_empty_box_checker[i][j].out; 
        }
        for(var k=0;k<size;k++){
            sum_of_row_values += value_contribution_to_rowsum_from_that_index[i][k];
        }
        sum_of_row_values === rowSums[i][2];
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
            
            value_contribution_to_columnsum_from_that_index[j][i] <== solution[i][j]*is_empty_box_checker_for_columns[i][j].out; 
        }
        for(var k=0;k<size;k++){
            sum_of_column_values += value_contribution_to_columnsum_from_that_index[j][k];
        }
        sum_of_column_values === columnSums[j][2];
    }
}

component main { public [rowSums, columnSums] } = Kakuro(5);
