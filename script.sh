export PCR0=67d6837caa5bf3c47d5c2dbcfffc6493541923d6340053acedb3d25e4d91e4238a3f47c9e851330bd54ac9804576fa21
export PCR1=67d6837caa5bf3c47d5c2dbcfffc6493541923d6340053acedb3d25e4d91e4238a3f47c9e851330bd54ac9804576fa21
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

export ENCLAVE_PACKAGE_ID=0x02ebc76efc84e8382b5fdad63063c726ecab72cf814d95aaccbd14c3c94e23c0

echo "ENCLAVE_PACKAGE_ID:" $ENCLAVE_PACKAGE_ID

export CAP_OBJECT_ID=0xe0260c4a17da330abf5061738535f0be9b40fb12163866f0bbdc28f27e012ae2
export ENCLAVE_CONFIG_OBJECT_ID=0x3e6fdf9685a5359ef9db6a6c0c1607a7b175beb009e1553c5674daaf62c0ef02
export EXAMPLES_PACKAGE_ID=0xa056cc469799fbbf93ef5b24963f0b6577964b203fd1445451e1ac9acd8e93d6
export AGENT_REGISTRY=0x4297ef81e857a5cc740cb74d4529a382c9913f4a299637e74f8f7fd607ce612c

echo "CAP_OBJECT_ID:" $CAP_OBJECT_ID
echo "ENCLAVE_CONFIG_OBJECT_ID:" $ENCLAVE_CONFIG_OBJECT_ID
echo "AGENT_REGISTRY:" $AGENT_REGISTRY
echo "EXAMPLES_PACKAGE_ID": $EXAMPLES_PACKAGE_ID

# this calls the update_pcrs onchain with the enclave cap and built PCRs, this can be reused to update PCRs if Rust server code is updated
# sui client call --function update_pcrs --module enclave --package $ENCLAVE_PACKAGE_ID --type-args "$EXAMPLES_PACKAGE_ID::$MODULE_NAME::$OTW_NAME" --args $ENCLAVE_CONFIG_OBJECT_ID $CAP_OBJECT_ID 0x$PCR0 0x$PCR1 0x$PCR2

# # # this script calls the get_attestation endpoint from your enclave url and use it to calls register_enclave onchain to register the public key, results in the created enclave object
# sh register_enclave.sh $ENCLAVE_PACKAGE_ID $EXAMPLES_PACKAGE_ID $ENCLAVE_CONFIG_OBJECT_ID $ENCLAVE_URL $MODULE_NAME $OTW_NAME

export ENCLAVE_OBJECT_ID=0xa05482fd39f4363e050cab95351e054f0b960c5aecfac074ebb762a8b36251ee

echo "ENCLAVE_OBJECT_ID:" $ENCLAVE_OBJECT_ID

# sh register_agent.sh \
#   $EXAMPLES_PACKAGE_ID \
#   $MODULE_NAME \
#   $OTW_NAME \
#   $ENCLAVE_OBJECT_ID \
#   "cdefa09ab9731de93e4ca685ad87523964e1cc4e4503fbb0bb6a76a4f39b82f4f123bcbf08c93f2c3f1e6ce57249b1328c33653964569087bdeb2738b28ab306" \
#   1747931043794 \
#   "24" \
#   $AGENT_REGISTRY \
#   1 \
#   "0x123"

sh consume_prompt.sh \
  $EXAMPLES_PACKAGE_ID \
  $MODULE_NAME \
  $OTW_NAME \
  $ENCLAVE_OBJECT_ID \
  "7e6e499dcd591534163b227c97863b1df868a90a82eee5285e01b8c09bf3ea24aeff51d5b9e4756d8bc088da848867c3a6c4b6dedd2b63c132c3d90fd34a4b06" \
  1747931138473 \
  "24" \
  $AGENT_REGISTRY
