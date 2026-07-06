#include <iostream>
#include <vector>
#include <windows.h>   
using namespace std;


void showRealMemory() {
    MEMORYSTATUSEX statex;
    statex.dwLength = sizeof(statex);

    GlobalMemoryStatusEx(&statex);

    cout << "\n===== REAL SYSTEM MEMORY (RAM) =====\n";
    cout << "Total RAM: " << statex.ullTotalPhys / (1024 * 1024) << " MB\n";
    cout << "Available RAM: " << statex.ullAvailPhys / (1024 * 1024) << " MB\n";
    cout << "Used RAM: " 
         << (statex.ullTotalPhys - statex.ullAvailPhys) / (1024 * 1024)
         << " MB\n";
    cout << "====================================\n";
}

class ResourceManager {
private:
    vector<int> available;
    // FIXED: Added space between > > to support older C++98 compilers
    vector<vector<int> > allocation; 
    int processes, resources;

public:
    ResourceManager(int p, int r) {
        processes = p;
        resources = r;

        available.resize(resources);
        // FIXED: Added space between > > inside the nested constructor vector layout
        allocation.resize(processes, vector<int>(resources, 0)); 

        cout << "Enter available resources:\n";
        for (int i = 0; i < resources; i++) {
            cout << "Resource " << i + 1 << ": ";
            cin >> available[i];
        }
    }

    void allocateResource(int pid, vector<int> request) {
        bool possible = true;

        for (int i = 0; i < resources; i++) {
            if (request[i] > available[i]) {
                possible = false;
                break;
            }
        }

        if (possible) {
            for (int i = 0; i < resources; i++) {
                available[i] -= request[i];
                allocation[pid][i] += request[i];
            }
            cout << "Resources allocated successfully.\n";
        } else {
            cout << "Allocation failed! Not enough resources.\n";
        }
    }

    void releaseResource(int pid, vector<int> release) {
        for (int i = 0; i < resources; i++) {
            if (release[i] <= allocation[pid][i]) {
                allocation[pid][i] -= release[i];
                available[i] += release[i];
            }
        }
        cout << "Resources released.\n";
    }

    void display() {
        cout << "\n===== SIMULATED SYSTEM =====\n";

        cout << "\nAvailable Resources:\n";
        for (int i = 0; i < resources; i++) {
            cout << available[i] << " ";
        }

        cout << "\n\nAllocation Matrix:\n";
        for (int i = 0; i < processes; i++) {
            cout << "P" << i << ": ";
            for (int j = 0; j < resources; j++) {
                cout << allocation[i][j] << " ";
            }
            cout << endl;
        }

        cout << "============================\n";
    }
};

int main() {
    int p, r;

    cout << "Enter number of processes: ";
    cin >> p;

    cout << "Enter number of resource types: ";
    cin >> r;

    ResourceManager rm(p, r);

    int choice;

    do {
        cout << "\n===== MENU =====\n";
        cout << "1. Allocate Resources\n";
        cout << "2. Release Resources\n";
        cout << "3. Display Simulated Status\n";
        cout << "4. Show Real System Memory (RAM)\n";
        cout << "5. Exit\n";
        cout << "Enter choice: ";
        cin >> choice;

        if (choice == 1) {
            int pid;
            cout << "Enter Process ID (0-" << p - 1 << "): ";
            cin >> pid;

            vector<int> req(r);
            cout << "Enter resource request:\n";
            for (int i = 0; i < r; i++) {
                cin >> req[i];
            }

            rm.allocateResource(pid, req);
        }
        else if (choice == 2) {
            int pid;
            cout << "Enter Process ID (0-" << p - 1 << "): ";
            cin >> pid;

            vector<int> rel(r);
            cout << "Enter resources to release:\n";
            for (int i = 0; i < r; i++) {
                cin >> rel[i];
            }

            rm.releaseResource(pid, rel);
        }
        else if (choice == 3) {
            rm.display();
        }
        else if (choice == 4) {
            showRealMemory();  
        }

    } while (choice != 5);

    return 0;
}
