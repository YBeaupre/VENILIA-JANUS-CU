#ifndef TUBCIPHER
#define TUBCIPHER

char* roundEnc(char bitString[], char bigKey[], char smallKey[]);

char* roundDec(char bitString[], char bigKey[], char smallKey[]);

char* encrypt(char plaintext[], char key[]);

char* decrypt(char ciphertext[], char key[]);

#endif