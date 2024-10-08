#include <cstdio>
#include "cpu.h"

#include "common.h"

namespace StreamCompaction {
    namespace CPU {
        using StreamCompaction::Common::PerformanceTimer;
        PerformanceTimer& timer()
        {
            static PerformanceTimer timer;
            return timer;
        }

        /**
         * CPU scan (prefix sum).
         * For performance analysis, this is supposed to be a simple for loop.
         * (Optional) For better understanding before starting moving to GPU, you can simulate your GPU scan in this function first.
         */
        void scan(int n, int *odata, const int *idata, bool useTimer) {
            if (useTimer) timer().startCpuTimer();
            odata[0] = 0;
            for (int i = 1; i < n; ++i) {
                int input = idata[i - 1];
                int last_output = odata[i - 1];
                odata[i] = input + last_output;
            }
            if (useTimer) timer().endCpuTimer();
        }

        /**
         * CPU stream compaction without using the scan function.
         *
         * @returns the number of elements remaining after compaction.
         */
        int compactWithoutScan(int n, int *odata, const int *idata) {
            timer().startCpuTimer();
            int numOutputElements = 0;
            for (int i = 0; i < n; ++i) {
                int input = idata[i];
                if (input == 0) continue;
                odata[numOutputElements] = input;
                ++numOutputElements;
            }
            timer().endCpuTimer();
            return numOutputElements;
        }

        /**
         * CPU stream compaction using scan and scatter, like the parallel version.
         *
         * @returns the number of elements remaining after compaction.
         */
        int compactWithScan(int n, int *odata, const int *idata) {
            int* trueFalseArray = new int[n];
            int* scannedTFArray = new int[n];

            timer().startCpuTimer();
            for (int i = 0; i < n; ++i) {
                int input = idata[i];
                trueFalseArray[i] = (input == 0) ? 0 : 1;
            }

            scan(n, scannedTFArray, trueFalseArray, false);

            // Scatter
            int numOutputElements = 0;
            for (int i = 0; i < n; ++i) {
                int input = idata[i];
                int trueFalseValue = trueFalseArray[i];
                if (!trueFalseValue) continue;

                odata[scannedTFArray[i]] = input;
                ++numOutputElements;
            }

            timer().endCpuTimer();

            delete[] trueFalseArray;
            delete[] scannedTFArray;
            return numOutputElements;
        }
    }
}
