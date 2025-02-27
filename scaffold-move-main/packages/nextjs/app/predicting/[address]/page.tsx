"use client";

import React from 'react';
import { LineChart, Line, XAxis, YAxis, ResponsiveContainer } from 'recharts';
import useSubmitTransaction from "~~/hooks/scaffold-move/useSubmitTransaction";
import { useView } from "~~/hooks/scaffold-move/useView";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { AddressInput } from "~~/types/scaffold-move";

interface PredictionOption {
  outcome: string;
  chance: number;
  moveAmount: number;
}

const PredictionPage = ({ params }) => {
  const { account } = useWallet();

  const { submitTransaction, transactionResponse, transactionInProcess } = useSubmitTransaction("PoILiquidityPool");

  const {
    data: marketData,
    isLoading: isLoadingBioView,
    refetch: refetchBioView,
  } = useView({ moduleName: "TestMarketAbstraction", functionName: "view_market", args: [params.address] });
  console.log(marketData)

  const {
    data: lp,
    isLoading: isLoadinglpView,
    refetch: refetchliView,
  } = useView({ moduleName: "TestMarketAbstraction", functionName: "view_lp_addr", args: [account?.address as AddressInput,params.address] });
  console.log(lp)

  const chartData = [
    { date: 'Feb 7', blue: 45, red: 20, green: 10 },
    { date: 'Feb 10', blue: 40, red: 25, green: 12 },
    { date: 'Feb 13', blue: 35, red: 30, green: 15 },
    { date: 'Feb 16', blue: 38, red: 32, green: 14 },
    { date: 'Feb 19', blue: 36, red: 34, green: 13 }
  ];

  const predictions: PredictionOption[] = [
    { outcome: 'A*', chance: 80, moveAmount: 0.8 },
    { outcome: 'A', chance: 9, moveAmount: 0.09 },
    { outcome: 'B', chance: 8, moveAmount: 0.08 },
    { outcome: 'C', chance: 1, moveAmount: 0.01 },
    { outcome: 'D', chance: 1, moveAmount: 0.01 },
    { outcome: 'E', chance: 1, moveAmount: 0.01 }
  ];

  const buyTicket = async (id: number) => {
    try {
      await submitTransaction("buy_ticket", [id, 1, lp[0]]);

      // await fetchBio();
      if (transactionResponse?.transactionSubmitted) {
        console.log("Transaction successful:", transactionResponse.success ? "success" : "failed");
      }
    } catch (error) {
      console.error("Error registering bio:", error);
    }
  };

  return (
    <div className="max-w-4xl mx-auto p-4 space-y-6">
      <div className="flex items-center justify-between bg-white rounded-lg p-4 shadow">
        <div className="text-xl font-semibold">{params.address}</div>
        <button className="text-gray-600">▼</button>
      </div>

      <div className="bg-white rounded-lg shadow-lg p-6">
        <div className="flex items-start gap-4">
          <div className="w-8 h-8 rounded-full bg-gray-200 flex-shrink-0" /> {/* Avatar placeholder */}
          <div className="flex-1">
            <h2 className="text-lg font-semibold mb-4">
              {marketData?.length && marketData[0]?.title}
            </h2>
            
            <div className="h-64 mb-6">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={chartData}>
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Line type="monotone" dataKey="blue" stroke="#2563eb" strokeWidth={2} />
                  <Line type="monotone" dataKey="red" stroke="#dc2626" strokeWidth={2} />
                  <Line type="monotone" dataKey="green" stroke="#16a34a" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            </div>

            <div className="flex gap-6 mb-6 text-sm">
              <span className="flex items-center gap-2">
                <span className="w-3 h-3 bg-blue-600 rounded-full"></span>
                $250B 37%
              </span>
              <span className="flex items-center gap-2">
                <span className="w-3 h-3 bg-red-600 rounded-full"></span>
                $50B 36%
              </span>
              <span className="flex items-center gap-2">
                <span className="w-3 h-3 bg-green-600 rounded-full"></span>
                $200-250B 10%
              </span>
            </div>

            <div className="flex justify-between items-center mb-6 p-4 bg-gray-50 rounded-lg">
              <div className="text-lg font-medium">&lt;$50B</div>
              <div className="flex gap-2">
                <button className="px-4 py-2 bg-green-500 text-white rounded-md hover:bg-green-600 transition-colors">
                  Yes 36¢
                </button>
                <button className="px-4 py-2 bg-gray-200 rounded-md hover:bg-gray-300 transition-colors">
                  No 65¢
                </button>
              </div>
            </div>

            <div className="mb-6">
              <div className="text-sm font-medium mb-2">Amount</div>
              <div className="flex gap-2">
                <button className="px-4 py-2 border rounded-md hover:bg-gray-50">+$1</button>
                <button className="px-4 py-2 border rounded-md hover:bg-gray-50">+$20</button>
                <button className="px-4 py-2 border rounded-md hover:bg-gray-50">+$100</button>
                <button className="px-4 py-2 border rounded-md hover:bg-gray-50">Max</button>
              </div>
            </div>

            <button className="w-full mb-6 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors">
              Login to Trade
            </button>

            <div className="rounded-lg border border-gray-200 overflow-hidden">
              <div className="grid grid-cols-3 bg-gray-50 text-sm font-medium">
                <div className="px-4 py-2">Outcomes</div>
                <div className="px-4 py-2">Chances</div>
                <div className="px-4 py-2 text-right">Action</div>
              </div>
              {marketData?.length && marketData[0]?.options.map((prediction, index) => (
                <div key={index} className="grid grid-cols-3 border-t border-gray-200">
                  <div className="px-4 py-2">{prediction}</div>
                  <div className="px-4 py-2">{100 / marketData[0]?.options.length}</div>
                  <div className="px-4 py-2 text-right">
                    <button className="px-3 py-1 border rounded-md hover:bg-gray-50 transition-colors" onClick={() => buyTicket(index)}>
                      Buy {prediction.moveAmount} Move
                    </button>
                  </div>
                </div>
              ))}
            </div>

            <div className="mt-4 text-sm text-gray-500">
              By trading, you agree to the Terms of Use
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PredictionPage;