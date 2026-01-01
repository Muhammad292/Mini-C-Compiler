// Invalid program - type mismatch
int main() {
    int x;
    bool y;
    
    x = 10;
    y = x;  // ERROR: assigning int to bool
    
    return 0;
}
