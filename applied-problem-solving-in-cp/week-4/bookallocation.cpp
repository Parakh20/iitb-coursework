class Solution {
public:
    bool check(vector<int> &arr, int k, int pageLimit) {
        int cnt = 1;
        int pageSum = 0;
        for(int i = 0; i < arr.size(); i++) {
            if (arr[i] > pageLimit) return false; // Extra safety check
            if (pageSum + arr[i] > pageLimit) {
                cnt++;
                pageSum = arr[i];
            } else {
                pageSum += arr[i];
            }
        }
        return (cnt <= k);
    }

    int findPages(vector<int> &arr, int k) {
        if (k > arr.size()) return -1;

        int low = *max_element(arr.begin(), arr.end());  // at least the largest book
        int high = accumulate(arr.begin(), arr.end(), 0); // at most the sum of all pages
        int ans = -1;

        while (low <= high) {
            int mid = low + (high - low) / 2;

            if (check(arr, k, mid)) {
                ans = mid;         // valid, try smaller max
                high = mid - 1;
            } else {
                low = mid + 1;     // invalid, increase limit
            }
        }
        return ans;
    }
};
