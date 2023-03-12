const hre = require("hardhat");
const {assert} = require("chai");
require("console.mute");

const invalidInput1 = require("./invalid-inputs/invalidInput1.json");
const invalidInput2 = require("./invalid-inputs/invalidInput2.json");
const validInput = require("./valid-inputs/validInput1.json");

describe("kakuro circuit", () => {
	let circuit;
  
	before(async () => {
		circuit = await hre.circuitTest.setup("kakuro");
	});

	it("should satisfy all the valid inputs", async () => {
		const witness = await circuit.calculateWitness(validInput, true);
		await circuit.checkConstraints(witness);
	});

  it("should fail on all invalid inputs", async () => {
    let isValidInput = false;

    for (let invalidInput of [invalidInput1, invalidInput2]) {
      try {
        console.mute();
        
        const witness = await circuit.calculateWitness(invalidInput, true);
        await circuit.checkConstraints(witness);
  
        isValidInput = true;
        console.resume();
      }
      catch (err) {
        console.resume();
      }
  
      assert.isFalse(isValidInput);
    }
	});
});
