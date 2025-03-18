import argparse

def encode(key: str, text: str) -> None:
    encoded_text: str = ""

    for i, char in enumerate(text):
        code: int = (ord(char) - ord('A') + ord(key[i % len(key)]) - ord('A')) % 26
        encoded_text += chr(code + ord('A'))

    print(encoded_text)

def main() -> None:
    parser = argparse.ArgumentParser(description="String Encoder")
    
    parser.add_argument("-k", "--key", type=str, required=True,
                        help="Key to use for encoding")

    parser.add_argument("-t", "--text", type=str, required=True,
                        help="Text to encode")

    args = parser.parse_args()

    key: str = args.key
    text: str = args.text

    encode(key, text)

if __name__ == "__main__":
    main()
