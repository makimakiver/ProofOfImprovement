"use client";

import React, { useState } from 'react';
import useSubmitTransaction from "~~/hooks/scaffold-move/useSubmitTransaction";
import { useView } from "~~/hooks/scaffold-move/useView";

const CompetitionInvitation = ({ params }) => {
  const { submitTransaction, transactionResponse, transactionInProcess } = useSubmitTransaction("TestMarketAbstraction");

  const {
    data: marketData,
    isLoading: isLoadingBioView,
    refetch: refetchBioView,
  } = useView({ moduleName: "TestMarketAbstraction", functionName: "view_market_obj", args: [params?.address, process.env.NEXT_PUBLIC_REGISTRY_ACCOUNT_ADDRESS] });

  console.log(marketData);

  const [listInMarket, setListInMarket] = useState<string>("");
  const [submitting, setSubmitting] = useState<boolean>(false);
  const [error, setError] = useState<string>("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!listInMarket) {
      setError("Please select whether you want to be listed in the prediction market");
      return;
    }
    
    setError("");
    setSubmitting(true);

    try {
      await submitTransaction("new_respond_invitation", [process.env.NEXT_PUBLIC_REGISTRY_ACCOUNT_ADDRESS, listInMarket === "yes", true, params?.id]);

      if (transactionResponse?.transactionSubmitted) {
        console.log("Transaction successful:", transactionResponse.success ? "success" : "failed");
      }
    } catch (error) {
      console.error("Error creating market place:", error);
    }
    
    console.log({
      competition: competition.name,
      listInMarket: listInMarket === "yes"
    });
    
    alert(`You have successfully joined the "${competition.name}" competition!`);
    setSubmitting(false);
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4">
      <div className="max-w-lg mx-auto bg-white rounded-lg shadow-md overflow-hidden">
        <div className="bg-indigo-600 px-6 py-4">
          <h1 className="text-xl font-bold text-white">Competition Invitation {params?.address} {params?.id}</h1>
        </div>
        
        <div className="px-6 py-4 border-b">
          <h2 className="text-2xl font-bold text-gray-900 mb-2">{marketData?.length && marketData[0]?.title}</h2>

          <div>
            <h3 className="text-md font-medium text-gray-900 mb-3">Participants</h3>
            
            {/* <div className="bg-gray-50 rounded-md border border-gray-200">
              <div className="divide-y divide-gray-200">
                {marketData?.length > 0 && marketData[0]?.participants.map((participant, index) => (
                  <div key={index} className="px-4 py-3 flex justify-between items-center">
                    <p className="text-xs text-gray-500 font-mono">{(participant)}</p>
                  </div>
                ))}
              </div>
            </div> */}
          </div>
        </div>
        
        <form onSubmit={handleSubmit} className="px-6 py-4">
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Do you want to be listed in the prediction market?
            </label>
            
            <div className="space-y-2">
              <div className="flex items-center">
                <input
                  id="list-yes"
                  name="listInMarket"
                  type="radio"
                  className="h-4 w-4 text-indigo-600 border-gray-300 focus:ring-indigo-500"
                  value="yes"
                  checked={listInMarket === "yes"}
                  onChange={() => setListInMarket("yes")}
                />
                <label htmlFor="list-yes" className="ml-3 block text-sm text-gray-700">
                  Yes
                </label>
              </div>
              
              <div className="flex items-center">
                <input
                  id="list-no"
                  name="listInMarket"
                  type="radio"
                  className="h-4 w-4 text-indigo-600 border-gray-300 focus:ring-indigo-500"
                  value="no"
                  checked={listInMarket === "no"}
                  onChange={() => setListInMarket("no")}
                />
                <label htmlFor="list-no" className="ml-3 block text-sm text-gray-700">
                  No
                </label>
              </div>
            </div>
            
            {error && <p className="mt-2 text-sm text-red-600">{error}</p>}
          </div>
          
          {/* Terms & Conditions */}
          <div className="mb-6">
            <p className="text-sm text-gray-500">
              By joining this competition, you agree to the competition rules and terms of service.
            </p>
          </div>
          
          <div>
            <button
              type="submit"
              disabled={submitting}
              className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-75"
            >
              {submitting ? (
                <>
                  <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Joining...
                </>
              ) : (
                'Join Competition'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CompetitionInvitation;