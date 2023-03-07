#include <stdio.h>
#include "TUBCipher.h"

char* XOR(char bitString[], char key[]) {
	/*
	* bitString: 27-bit block
	* key: 27-bit key
	* Output: bitString_i XOR key_i (for every bit in position i)
	*/

	char result[27];
	int leftBit;
	int rightBit;


	for (int i = 0; i < 27; i++) {
		leftBit = bitString[i] - '0';
		rightBit = key[i] - '0';
		result[i] = (leftBit ^ rightBit) + '0';
	}

	return result;
}

char* keyedPerm(char bitString[], char key[]) {
	/*
	* bitString: 27-bit block
	* key: 18-bit key
	* Output: key based permutation of 27-bit block
	*/

	char result[27];
	char c0;
	char c1;
	char c2;
	char a0;
	char a1;

	for (int i = 0; i < 9; i++) {
		c0 = bitString[3 * i];
		c1 = bitString[(3 * i) + 1];
		c2 = bitString[(3 * i) + 2];
		a0 = key[2 * i];
		a1 = key[(2 * i) + 1];

		if ((a0 == '0') && (a1 == '0')) {
			result[3 * i] = c0;
			result[(3 * i) + 1] = c1;
			result[(3 * i) + 2] = c2;
		}
		else if ((a0 == '0') && (a1 == '1')) {
			result[3 * i] = c1;
			result[(3 * i) + 1] = c0;
			result[(3 * i) + 2] = c2;
		}
		else if ((a0 == '1') && (a1 == '0')) {
			result[3 * i] = c0;
			result[(3 * i) + 1] = c2;
			result[(3 * i) + 2] = c1;
		}
		else {
			result[3 * i] = c2;
			result[(3 * i) + 1] = c1;
			result[(3 * i) + 2] = c0;
		}

	}
	return result;
}

char* roundEnc(char bitString[], char bigKey[], char smallKey[]) {
	/*
	* bitString: 27-bit block to be encrypted
	* bigKey: 27-bit key
	* smallKey: 18-bit key
	* Output: a single round of the permutation-substitution network applied to the 27-bit block for encryption
	*/
	
	//XOR
	char* xorBits = XOR(bitString, bigKey);

	//Fixed permutation
	char resultPerm[27];
	for (int i = 0; i < 26; i++) {
		resultPerm[(3 * i) % 26] = xorBits[i];
	}
	resultPerm[26] = xorBits[26];

	//Keyed permutation
	char *currentResult = keyedPerm(resultPerm, smallKey);

	//Fixed substitution
	char result[27];
	int W = 0;

	for (int i = 0; i < 9; i++) {
		W = 0;

		if (currentResult[3 * i] == '1') {
			W += 100;
		}

		if (currentResult[(3 * i) + 1] == '1') {
			W += 10;
		}

		if (currentResult[(3 * i) + 2] == '1') {
			W += 1;
		}

		if (W == 0) {
			//0 -> 0
			result[3 * i] = '0';
			result[(3 * i) + 1] = '0';
			result[(3 * i) + 2] = '0';
		}
		else if (W == 1) {
			//1 -> 1
			result[3 * i] = '0';
			result[(3 * i) + 1] = '0';
			result[(3 * i) + 2] = '1';
		}
		else if (W == 10) {
			//2 -> 3
			result[3 * i] = '0';
			result[(3 * i) + 1] = '1';
			result[(3 * i) + 2] = '1';
		}
		else if (W == 11) {
			//3 -> 6
			result[3 * i] = '1';
			result[(3 * i) + 1] = '1';
			result[(3 * i) + 2] = '0';
		}
		else if (W == 100) {
			//4 -> 7
			result[3 * i] = '1';
			result[(3 * i) + 1] = '1';
			result[(3 * i) + 2] = '1';
		}
		else if (W == 101) {
			//5 -> 4
			result[3 * i] = '1';
			result[(3 * i) + 1] = '0';
			result[(3 * i) + 2] = '0';
		}
		else if (W == 110) {
			//6 -> 5
			result[3 * i] = '1';
			result[(3 * i) + 1] = '0';
			result[(3 * i) + 2] = '1';
		}
		else {
			//7 -> 2
			result[3 * i] = '0';
			result[(3 * i) + 1] = '1';
			result[(3 * i) + 2] = '0';
		}
	}

	return result;

}

char* roundDec(char bitString[], char bigKey[], char smallKey[]) {
	/*
	* bitString: 27-bit block to be decrypted
	* bigKey: 27-bit key
	* smallKey: 18-bit key
	* Output: a single round of the permutation-substitution network applied to the 27-bit block for decryption
	*/

	//Fixed substitution
	char resultSub[27];
	int W = 0;

	for (int i = 0; i < 9; i++) {
		W = 0;

		if (bitString[3 * i] == '1') {
			W += 100;
		}

		if (bitString[(3 * i) + 1] == '1') {
			W += 10;
		}

		if (bitString[(3 * i) + 2] == '1') {
			W += 1;
		}

		if (W == 0) {
			//0 -> 0
			resultSub[3 * i] = '0';
			resultSub[(3 * i) + 1] = '0';
			resultSub[(3 * i) + 2] = '0';
		}
		else if (W == 1) {
			//1 -> 1
			resultSub[3 * i] = '0';
			resultSub[(3 * i) + 1] = '0';
			resultSub[(3 * i) + 2] = '1';
		}
		else if (W == 10) {
			//2 -> 7
			resultSub[3 * i] = '1';
			resultSub[(3 * i) + 1] = '1';
			resultSub[(3 * i) + 2] = '1';
		}
		else if (W == 11) {
			//3 -> 2
			resultSub[3 * i] = '0';
			resultSub[(3 * i) + 1] = '1';
			resultSub[(3 * i) + 2] = '0';
		}
		else if (W == 100) {
			//4 -> 5
			resultSub[3 * i] = '1';
			resultSub[(3 * i) + 1] = '0';
			resultSub[(3 * i) + 2] = '1';
		}
		else if (W == 101) {
			//5 -> 6
			resultSub[3 * i] = '1';
			resultSub[(3 * i) + 1] = '1';
			resultSub[(3 * i) + 2] = '0';
		}
		else if (W == 110) {
			//6 -> 3
			resultSub[3 * i] = '0';
			resultSub[(3 * i) + 1] = '1';
			resultSub[(3 * i) + 2] = '1';
		}
		else {
			//7 -> 4
			resultSub[3 * i] = '1';
			resultSub[(3 * i) + 1] = '0';
			resultSub[(3 * i) + 2] = '0';
		}
	}

	//Keyed permutation
	char *resultPerm = keyedPerm(resultSub, smallKey);

	//Fixed permutation
	char currentResult[27];
	for (int i = 0; i < 26; i++) {
		currentResult[i] = resultPerm[(3 * i) % 26];
	}
	currentResult[26] = resultPerm[26];

	//XOR
	char *result = XOR(currentResult, bigKey);

	return result;
}

char* encrypt(char plaintext[], char key[]) {
	/*
	* plaintext: 27-bit block to be encrypted
	* key: 2560-bit key
	* Output: encrypted 27-bit block
	*/

	char bitString[27];
	strncpy(bitString, plaintext, 27);

	//Complete 56 rounds of the substitution-permutation network
	for (int i = 0; i < 56;i++) {

		//Build subkeys
		char bigKey[27];
		char smallKey[18];
		
		for (int j = 0; j < 27; j++) {
			bigKey[j] = key[(45 * i)+j];
		}

		for (int j = 0; j < 18; j++) {
			smallKey[j] = key[(45 * i) + 27 + j];
		}

		char newBitString[27];
		strcpy(newBitString,roundEnc(bitString, bigKey, smallKey));

		for (int i = 0; i < 27; i++) {
			bitString[i] = newBitString[i];
		}
	}

	for (int i = 0; i < 27; i++) {
		printf("%c", bitString[i]);
	}

	return bitString;
}

char* decrypt(char ciphertext[], char key[]) {
	/*
	* ciphertext: 27-bit block to be decrypted
	* key: 2560-bit key
	* Output: decrypted 27-bit block
	*/

	char bitString[27];
	strncpy(bitString, ciphertext, 27);

	//Complete 56 rounds of the substitution-permutation network
	for (int i = 55; i > -1; i--) {

		//Build subkeys
		char bigKey[27];
		char smallKey[18];

		for (int j = 0; j < 27; j++) {
			bigKey[j] = key[(45 * i) + j];
		}

		for (int j = 0; j < 18; j++) {
			smallKey[j] = key[(45 * i) + 27 + j];
		}

		char newBitString[27];
		strcpy(newBitString, roundDec(bitString, bigKey, smallKey));

		for (int i = 0; i < 27; i++) {
			bitString[i] = newBitString[i];
		}
	}
	return bitString;
}

int main() {
	//Read ciphertext from file
	char ciphertext[27];
	FILE *fileCiphertext = fopen("build/ciphertext.txt", "r");
	for (int i = 0; i < 27; i++) {
		ciphertext[i] = fgetc(fileCiphertext);
	}
	fclose(fileCiphertext);

	//Read extended key from file
	char extendedKey[2560];
	FILE* fileKey = fopen("build/extendedKey.txt", "r");
	for (int i = 0; i < 2560; i++) {
		extendedKey[i] = fgetc(fileKey);
	}
	fclose(fileKey);

	//Decrypt plaintext
	char plaintext[27];
	strcpy(plaintext, decrypt(ciphertext, extendedKey));

	//Output to file
	FILE* filePlaintext = fopen("build/plaintext.txt", "w");
	for (int i = 0; i < 27; i++) {
		fprintf(filePlaintext, "%c", plaintext[i]);
	}
}