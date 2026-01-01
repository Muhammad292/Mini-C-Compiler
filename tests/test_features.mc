// Test all features step by step
int x;

int add(int a, int b) {
    return a + b;
}

int main() {
    int y;
    bool flag;
    
    y = 10;
    flag = true;
    
    // Boolean operations
    if (flag && (y > 5)) {
        output(y);
    }
    
    // While loop
    while (y > 0) {
        y = y - 1;
    }
    
    // For loop  
    for (y = 0; y < 5; y = y + 1) {
        output(y);
    }
    
    return 0;
}
