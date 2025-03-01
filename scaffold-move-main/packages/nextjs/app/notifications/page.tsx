"use client";

import React, { useState } from 'react';
import { useRouter } from "next/navigation";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useView } from "~~/hooks/scaffold-move/useView";
import { AddressInput } from "~~/types/scaffold-move";

const Notifications = () => {
  const router = useRouter();
  const { account } = useWallet();

  const {
    data: invitations,
    isLoading: isLoadingBioView,
    refetch: refetchBioView,
  } = useView({ moduleName: "TestMarketAbstraction", functionName: "view_invitation", args: [account?.address as AddressInput, process.env.NEXT_PUBLIC_REGISTRY_ACCOUNT_ADDRESS] });

  const {
    data: require_submit_market,
    isLoading: isLoadingSubmitView,
    refetch: refetchSubmitView,
  } = useView({ moduleName: "TestMarketAbstraction", functionName: "view_require_submit_market", args: [account?.address as AddressInput, process.env.NEXT_PUBLIC_REGISTRY_ACCOUNT_ADDRESS] });

  const {
    data: view_validation,
  } = useView({ moduleName: "TestMarketAbstraction", functionName: "view_validation", args: [account?.address as AddressInput, process.env.NEXT_PUBLIC_REGISTRY_ACCOUNT_ADDRESS] });

  console.log(view_validation);

  const {
    data: view_validation_not_submitted,
  } = useView({ moduleName: "TestMarketAbstraction", functionName: "view_validation_not_submitted", args: [account?.address as AddressInput, process.env.NEXT_PUBLIC_REGISTRY_ACCOUNT_ADDRESS] });

  console.log(view_validation_not_submitted);

  const [activeTab, setActiveTab] = useState('invitation');
  
  const markets = [
    { id: 1, title: '<Market title1>', publicKey: '<Public key1>', reward: '12.68Move' },
    { id: 2, title: '<Market title2>', publicKey: '<Public key2>', reward: '18Move' },
    { id: 3, title: '<Market title3>', publicKey: '<Public key3>', reward: '50.02Move' }
  ];

  const totalReward = '12.68Move';

  const TabBar = () => (
    <div className="flex border-b-2 border-gray-200 mb-8">
      <TabButton 
        id="invitation" 
        label="Market Invitation" 
        active={activeTab === 'invitation'} 
        onClick={() => setActiveTab('invitation')} 
      />
      <TabButton 
        id="validation" 
        label="Validation" 
        active={activeTab === 'validation'} 
        onClick={() => setActiveTab('validation')} 
      />
      <TabButton 
        id="rewards" 
        label="Claim rewards" 
        active={activeTab === 'rewards'} 
        onClick={() => setActiveTab('rewards')} 
      />
    </div>
  );

  const TabButton = ({ id, label, active, onClick }) => (
    <button 
      onClick={onClick}
      className={`px-6 py-3 relative font-medium text-base transition-colors duration-200 ${
        active ? 'text-black' : 'text-gray-500 hover:text-gray-800'
      }`}
    >
      {label}
      {active && (
        <div className="absolute bottom-0 left-0 w-full h-0.5 bg-red-500 transform translate-y-1"></div>
      )}
      <div className="absolute -top-1 -right-1 w-2.5 h-2.5 bg-red-500 rounded-full"></div>
    </button>
  );

  const MarketItem = ({ title, publicKey, children, link }) => (
    <div className="border-b border-gray-200 py-4 flex justify-between items-center group hover:bg-gray-50 transition-colors duration-150 px-2">
      <div className="cursor-pointer text-lg font-medium text-gray-800" onClick={() =>  router.push(link)}>{title}</div>
      {children}
    </div>
  );

  const InvitationTab = () => (
    <div className="space-y-1">
      {invitations?.map((invitation, i) => (
        <MarketItem key={i} title={"Exam"} link={`/notifications/competitioininvitation/${invitation}/${i}`}>
          <div className="text-sm text-gray-500">from <span className="font-mono text-gray-600">{invitation}</span></div>
        </MarketItem>
      ))}
    </div>
  );

  const ValidationTab = () => (
    <div className="space-y-1">
      {require_submit_market?.length && require_submit_market[0].map((market, i) => (
        <MarketItem key={i} title={'Exam'}>
          <div className="flex items-center gap-2">
            <div className="text-sm font-medium text-gray-700 cursor-pointer" onClick={() =>  router.push(`/submitresult/${market}`)}>Submit result</div>
            <div className="text-sm text-gray-500">from <span className="font-mono text-gray-600">{market}</span></div>
          </div>
        </MarketItem>
      ))}

      {view_validation_not_submitted?.length && view_validation_not_submitted[0].map((market, i) => (
        <MarketItem key={i} title={'Exam'}>
          <div className="flex items-center gap-2">
            <div className="text-sm font-medium text-gray-700 cursor-pointer" onClick={() =>  router.push("/validateresult")}>validate friends</div>
            <div className="text-sm text-gray-500">from <span className="font-mono text-gray-600">{market}</span></div>
          </div>
        </MarketItem>
      ))}
    </div>
  );

  const RewardsTab = () => (
    <div className="relative">
      <div className="space-y-1">
        {markets.map((market) => (
          <MarketItem key={market.id} title={market.title}>
            <button className="border border-gray-300 rounded-lg px-4 py-1.5 hover:bg-gray-100 transition-colors duration-150 text-gray-800 font-medium shadow-sm">
              Claim {market.reward}
            </button>
          </MarketItem>
        ))}
      </div>
      
      <div className="mt-12 text-center text-sm text-gray-600">
        will add {totalReward} to your wallet
      </div>
      
      <div className="mt-6 flex justify-center">
        <button className="border-2 border-gray-300 rounded-full px-10 py-2.5 hover:bg-gray-50 transition-colors duration-150 font-medium text-gray-800 shadow-sm">
          Claim All
        </button>
      </div>
    </div>
  );

  return (
    <div className="max-w-4xl mx-auto p-6">
      <div className="bg-white rounded-xl border border-gray-200 shadow-md p-8">
        <TabBar />
        
        {activeTab === 'invitation' && <InvitationTab />}
        {activeTab === 'validation' && <ValidationTab />}
        {activeTab === 'rewards' && <RewardsTab />}
      </div>
    </div>
  );
};

export default Notifications;