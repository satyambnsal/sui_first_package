export PCR0=d1c5f306a3f4ea1333445383999f9919f1220ccf75ab81651c9327e575ba3bfb35aab4ccc900923a266c05c8363a242c
export PCR1=d1c5f306a3f4ea1333445383999f9919f1220ccf75ab81651c9327e575ba3bfb35aab4ccc900923a266c05c8363a242c
export PCR2=21b9efbc184807662e966d34f390821309eeac6802309798826296bf3e8bec7c10edb30948c90ba67310f7b964fc500a
export ENCLAVE_URL=http://54.81.11.64:3000
export MODULE_NAME=sentinel
export OTW_NAME=SENTINEL

echo "PCRS"
echo 0x$PCR0
echo 0x$PCR1
echo 0x$PCR2

echo "module name": $MODULE_NAME
echo "otw name": $OTW_NAME
echo "ENCLAVE_URL: " $ENCLAVE_URL

export ENCLAVE_PACKAGE_ID=0x34156e47e20e0677fb0928bae101fe01f0c4b16ccdd5a690e17108d6616f7ba3

echo "ENCLAVE_PACKAGE_ID:" $ENCLAVE_PACKAGE_ID

export CAP_OBJECT_ID=0x13f2c06e7b73750d37c648260001e685f5ab4b0aad22722536c71b88d73e173d
export ENCLAVE_CONFIG_OBJECT_ID=0xe6af16140f99d4a9971db8d9c5ca8bcfd077935d99054cf4652ed93137fdde3e
export EXAMPLES_PACKAGE_ID=0xde2da60dca5e3143da9e0e0f277ed52c599bb354ecfeac091d1d186136c48f60
export AGENT_REGISTRY=0x3f9f1d7cbbdefd6f545df900ddd70a571dc2d2117d5cbf36912815708fe74b5e

echo "CAP_OBJECT_ID:" $CAP_OBJECT_ID
echo "ENCLAVE_CONFIG_OBJECT_ID:" $ENCLAVE_CONFIG_OBJECT_ID
echo "AGENT_REGISTRY:" $AGENT_REGISTRY
echo "EXAMPLES_PACKAGE_ID": $EXAMPLES_PACKAGE_ID

# this calls the update_pcrs onchain with the enclave cap and built PCRs, this can be reused to update PCRs if Rust server code is updated
# sui client call --function update_pcrs --module enclave --package $ENCLAVE_PACKAGE_ID --type-args "$EXAMPLES_PACKAGE_ID::$MODULE_NAME::$OTW_NAME" --args $ENCLAVE_CONFIG_OBJECT_ID $CAP_OBJECT_ID 0x$PCR0 0x$PCR1 0x$PCR2

# # this script calls the get_attestation endpoint from your enclave url and use it to calls register_enclave onchain to register the public key, results in the created enclave object
# sh register_enclave.sh $ENCLAVE_PACKAGE_ID $EXAMPLES_PACKAGE_ID $ENCLAVE_CONFIG_OBJECT_ID $ENCLAVE_URL $MODULE_NAME $OTW_NAME

export ENCLAVE_OBJECT_ID=0xc44f18c3c789ffddf485907d508a9d0ab88df05141fe835023ff3f01c6e4297c

echo "ENCLAVE_OBJECT_ID:" $ENCLAVE_OBJECT_ID

sh register_agent.sh \
  $EXAMPLES_PACKAGE_ID \
  $MODULE_NAME \
  $OTW_NAME \
  $ENCLAVE_OBJECT_ID \
  "5c900415379189ebe3d63644d9f7870d0aa169c4813bab2d4e93beca7996a51fd5c577654a6dc54fbac9fb857bfb23e826656c8c68ade20e8a78c075b161e90f" \
  1747912624473 \
  "720fb324-e20f-45a2-8706-5f58357ba180" \
  $AGENT_REGISTRY \
  1234 \
  "0x123"
