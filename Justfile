set positional-arguments

build_dir := "./build"
public_dir := "./src/web/public"

all:
  just compile RecruiterMove
  just compile AgentAsk
  just compile StartingMove

#
# Circom compilation
#
@compile c: build-dir powers-of-tau
  echo "Compiling {{c}}.circom..."
  mkdir -p {{build_dir}}/{{c}}
  circom src/circuits/{{c}}.circom --r1cs --wasm --sym --output {{build_dir}}/{{c}}
  snarkjs r1cs info {{build_dir}}/{{c}}/{{c}}.r1cs > /dev/null
  snarkjs groth16 setup {{build_dir}}/{{c}}/{{c}}.r1cs {{powers_of_tau}} {{build_dir}}/{{c}}/init.zkey > /dev/null
  snarkjs zkey contribute {{build_dir}}/{{c}}/init.zkey {{build_dir}}/{{c}}/final.zkey --name="1st Contributor Name" -v -e="random text" > /dev/null
  snarkjs zkey export verificationkey {{build_dir}}/{{c}}/final.zkey {{build_dir}}/{{c}}/verification_key.json > /dev/null
  snarkjs zkey export solidityverifier {{build_dir}}/{{c}}/final.zkey {{build_dir}}/{{c}}/{{c}}Verifier.sol > /dev/null
  # TODO bump solidity version

  sed -i sol 's/pragma solidity .*;/pragma solidity ^0.8.0;/' {{build_dir}}/{{c}}/{{c}}Verifier.sol
  sed -i sol 's/Pairing/{{c}}Pairing/g' {{build_dir}}/{{c}}/{{c}}Verifier.sol
  sed -i sol 's/contract Verifier/contract {{c}}Verifier/' {{build_dir}}/{{c}}/{{c}}Verifier.sol
  echo Done

#
# Powers of Tau setup
#
powers_of_tau_size := "18"
powers_of_tau_filename := "powersOfTau28_hez_final_" + powers_of_tau_size + ".ptau"
powers_of_tau_url := "https://hermez.s3-eu-west-1.amazonaws.com/" + powers_of_tau_filename
powers_of_tau := build_dir + "/" + powers_of_tau_filename

@powers-of-tau: build-dir
  [ -f {{powers_of_tau}} ] || wget {{powers_of_tau_url}} -O {{powers_of_tau}}

@build-dir:
  mkdir -p build

@prepare-all-js:
  just prepare-js RecruiterMove
  just prepare-js AgentAsk
  just prepare-js StartingMove

@prepare-js c: (js-dir c)
  cp {{build_dir}}/{{c}}/{{c}}_js/{{c}}.wasm {{public_dir}}/{{c}}
  cp {{build_dir}}/{{c}}/final.zkey {{public_dir}}/{{c}}

@js-dir c:
  mkdir -p {{public_dir}}/{{c}}

@compile-contracts:
  hardhat compile
