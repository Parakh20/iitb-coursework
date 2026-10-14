#include <bits/stdc++.h>
using namespace std;

bool canProduce(vector<long long>& machines, long long time, long long target) {
    long long totalProducts = 0;
    for (int i = 0; i < machines.size(); i++) {
        totalProducts += time / machines[i];
        // Early exit to avoid overflow
        if (totalProducts >= target) return true;
    }
    return totalProducts >= target;
}

long long minimumTime(vector<long long>& machines, long long target) {
    long long left = 1;
    long long right = *max_element(machines.begin(), machines.end()) * target;
    long long result = right;
    
    while (left <= right) {
        long long mid = left + (right - left) / 2;
        
        if (canProduce(machines, mid, target)) {
            result = mid;
            right = mid - 1;  // Try to find smaller time
        } else {
            left = mid + 1;   // Need more time
        }
    }
    
    return result;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n;
    long long l;
    cin >> n >> l;
    
    vector<long long> machines(n);
    for (int i = 0; i < n; i++) {
        cin >> machines[i];
    }
    
    cout << minimumTime(machines, l) << endl;
    
    return 0;
}
