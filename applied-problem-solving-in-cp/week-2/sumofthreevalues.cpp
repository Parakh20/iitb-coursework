
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n, x;
    cin >> n >> x;
    
    vector<pair<int, int>> nums(n); // {value, original_index}
    for (int i = 0; i < n; i++) {
        cin >> nums[i].first;
        nums[i].second = i;
    }
    
    // Sort while preserving original indices
    sort(nums.begin(), nums.end());
    
    // Two-pointer approach after fixing first element
    for (int i = 0; i < n - 2; i++) {
        int left = i + 1, right = n - 1;
        int target = x - nums[i].first;
        
        while (left < right) {
            int sum = nums[left].first + nums[right].first;
            
            if (sum == target) {
                // Found solution - convert back to 1-indexed original positions
                vector<int> indices = {nums[i].second + 1, nums[left].second + 1, nums[right].second + 1};
                sort(indices.begin(), indices.end());
                cout << indices[0] << " " << indices[1] << " " << indices[2] << endl;
                return 0;
            }
            else if (sum < target) {
                left++;
            }
            else {
                right--;
            }
        }
    }
    
    cout << "IMPOSSIBLE" << endl;
    return 0;
}
