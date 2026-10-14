#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin >> t;
    
    while (t--) {
        int n, m;
        cin >> n >> m;
        
        string x, s;
        cin >> x >> s;
        
        int operations = 0;
        bool found = false;
        
        while (x.length() <= 50 && !found) {
            if (x.find(s) != string::npos) {
                found = true;
                break;
            }
            
            x += x;
            operations++;
        }
        
        if (found) {
            cout << operations << "\n";
        } else {
            cout << -1 << "\n";
        }
    }
    
    return 0;
}
