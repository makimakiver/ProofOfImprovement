"use client";

import { useRouter } from "next/navigation";
import type { NextPage } from "next";
import { Bell } from 'lucide-react';
import { useView } from "~~/hooks/scaffold-move/useView";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { AddressInput } from "~~/types/scaffold-move";

interface Competition {
  id: string;
  title: string;
  participants: number;
  startDate: Date;
  endDate: Date;
}

const Home: NextPage = () => {
  const router = useRouter();
  const { account } = useWallet();

  const {
    data: marketList,
    isLoading: isLoadingBioView,
    refetch: refetchBioView,
  } = useView({ moduleName: "TestMarketAbstraction", functionName: "view_markets", args: [account?.address as AddressInput, process.env.NEXT_PUBLIC_REGISTRY_ACCOUNT_ADDRESS] });
  console.log(marketList)

  const {
    data: view_market_obj,
  } = useView({ moduleName: "TestMarketAbstraction", functionName: "view_market_obj", args: [account?.address as AddressInput, process.env.NEXT_PUBLIC_REGISTRY_ACCOUNT_ADDRESS] });
  console.log("view_market_obj", view_market_obj)

  const now = new Date();

  const CompetitionCard = ({ competition, isPast, id }: { competition: string; isPast: boolean; id: number }) => (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 hover:shadow-md transition-shadow">
      <div className="flex justify-between items-start mb-4">
        <div>
          <h3 className="font-medium text-lg text-gray-900">{competition?.title}</h3>
        </div>
        <div className="flex items-center gap-1">
          <div className="text-sm font-medium text-gray-900">{competition?.participants?.length}</div>
          <div className="text-sm text-gray-500">participants</div>
        </div>
      </div>

      <p>Market: {competition?.markets[0]}</p>
      <p>Owner: {competition.owner}</p>
      
      <div className="flex gap-2">
        {isPast ? (
          <>
            <button className="flex-1 px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200 transition-colors">
              View Results
            </button>
            <button className="flex-1 px-4 py-2 bg-blue-50 text-blue-700 rounded-md hover:bg-blue-100 transition-colors">
              View Analysis
            </button>
          </>
        ) : (
          <>
            <button onClick={() => router.push(`/predicting/${marketList[0][id]}/${id}`)} className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors">
              Join Competition
            </button>
            <button className="flex-1 px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200 transition-colors">
              Learn More
            </button>
          </>
        )}
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-6xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-2xl font-bold text-gray-900">Competitions Dashboard</h1>
          <Bell className="cursor-pointer" onClick={() => router.push("/notifications")} />
        </div>
        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold text-gray-900">Upcoming Competitions</h2>
            <div className="text-sm text-gray-500">{marketList?.length && marketList[0].length} competitions</div>
          </div>
          <div className="grid gap-4 md:grid-cols-2">
            {view_market_obj?.length && view_market_obj[0]?.map((competition, i) => (
              <CompetitionCard key={i} id={i} competition={competition} isPast={false} />
            ))}
            {marketList?.length && marketList[0] === 0 && (
              <div className="col-span-2 text-center py-8 text-gray-500">
                No upcoming competitions at the moment
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Home;
