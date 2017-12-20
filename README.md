# mipt-prog-lang


```
./lsb.erl img.bmp img2.bmp "Test message. Русские символы будут удалены. Let's try lsb decoding..."

Source text: "Test message. \x{420}\x{443}\x{441}\x{441}\x{43A}\x{438}\x{435} \x{441}\x{438}\x{43C}\x{432}\x{43E}\x{43B}\x{44B} \x{431}\x{443}\x{434}\x{443}\x{442} \x{443}\x{434}\x{430}\x{43B}\x{435}\x{43D}\x{44B}. Let's try lsb decoding..."
Filtered text: "Test message.    . Let's try lsb decoding..."

Head size: 122, cont.size: 120

./lsb.erl img2.bmp

Head size: 122, cont.size: 120

Decoded text: "Test message.    . Let's try lsb decodin"
```
