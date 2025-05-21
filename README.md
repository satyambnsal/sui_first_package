sui client ptb \
	--assign forge @0x0ecc22b3a5e6b5c1c08e81aa9c692dc35bea714249c94a37b0e75eeb2af08c2f \
	--assign to_address @0xc647dfdb8d8b575809902c9b86a26b6ace9f9271dfe5385468f503833a237177 \
	--move-call 0xa5f54851e652101c072adeccc422463f92bbb3436d86e51322a380a1055cd89e::example::sword_create forge 3 3 \
	--assign sword \
	--transfer-objects "[sword]" to_address \
	--gas-budget 20000000
