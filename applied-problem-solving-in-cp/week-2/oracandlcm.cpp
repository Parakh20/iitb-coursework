#include <bits/stdc++.h>
using namespace std;

long long gcd(long long a, long long b) {
    return b == 0 ? a : gcd(b, a % b);
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n;
    cin >> n;
    vector<long long> a(n);
    for (int i = 0; i < n; i++) {
        cin >> a[i];
    }
    
    // Compute suffix GCD
    vector<long long> suf(n + 1, 0);
    for (int i = n - 1; i >= 0; i--) {
        suf[i] = gcd(suf[i + 1], a[i]);
    }
    
    long long ans = 0;
    for (int i = 0; i < n - 1; i++) {
        // For element a[i], compute GCD of all LCMs involving a[i]
        long long lcm_gcd = a[i] * suf[i + 1] / gcd(a[i], suf[i + 1]);
        ans = gcd(ans, lcm_gcd);
    }
    
    cout << ans << endl;
    return 0;
}
