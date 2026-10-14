class Solution {
public:
    // Helper to check if we can paint with current maxTime using at most k painters
    bool isPossible(vector<int>& arr, int k, int maxTime) {
        int painters = 1, total = 0;

        for (int i = 0; i < arr.size(); i++) {
            if (arr[i] > maxTime) return false; // A single board is too long
            if (total + arr[i] > maxTime) {
                painters++;         // assign to new painter
                total = arr[i];     // reset sum for new painter
            } else {
                total += arr[i];    // accumulate time
            }
        }
        return painters <= k;
    }

    int minTime(vector<int>& arr, int k) {
        int low = *max_element(arr.begin(), arr.end());   // Min possible time
        int high = accumulate(arr.begin(), arr.end(), 0); // Max possible time
        int ans = -1;

        while (low <= high) {
            int mid = low + (high - low) / 2;
            if (isPossible(arr, k, mid)) {
                ans = mid;      // valid, try for smaller
                high = mid - 1;
            } else {
                low = mid + 1;  // not valid, try for larger
            }
        }
        return ans;
    }
};
