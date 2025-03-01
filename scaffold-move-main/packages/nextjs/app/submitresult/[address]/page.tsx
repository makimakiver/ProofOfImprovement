"use client";

import React, { useState } from 'react';
import { useRouter } from "next/navigation";
import { useView } from "~~/hooks/scaffold-move/useView";
import useSubmitTransaction from "~~/hooks/scaffold-move/useSubmitTransaction";

const SubmitResultPage = ({ params }) => {
  const router = useRouter();

  const { submitTransaction, transactionResponse, transactionInProcess } = useSubmitTransaction("TestMarketAbstraction");
 
  const {
    data: marketData,
    isLoading: isLoadingBioView,
    refetch: refetchBioView,
  } = useView({ moduleName: "TestMarketAbstraction", functionName: "view_market", args: [params?.address] });

  console.log(marketData);
  
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [selectedResult, setSelectedResult] = useState('');
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [errors, setErrors] = useState({
    marketTitle: '',
    file: '',
    result: ''
  });

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0] || null;
    setSelectedFile(file);
    
    if (file) {
      const url = URL.createObjectURL(file);
      setPreviewUrl(url);
    } else {
      setPreviewUrl(null);
    }
  };

  const validateForm = () => {
    const newErrors = {
      marketTitle: '',
      file: '',
      result: ''
    };
    
    let isValid = true;
    
    if (!selectedFile) {
      newErrors.file = 'Please upload a photo of your result';
      isValid = false;
    }
    
    if (!selectedResult) {
      newErrors.result = 'Please select your result';
      isValid = false;
    }
    
    setErrors(newErrors);
    return isValid;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const url = "https://images.unsplash.com/photo-1606326608606-aa0b62935f2b";
    
    try {
      await submitTransaction("create_validation", [selectedResult, url, process.env.NEXT_PUBLIC_REGISTRY_ACCOUNT_ADDRESS, params.address]);

      if (transactionResponse?.transactionSubmitted) {
        console.log("Transaction successful:", transactionResponse.success ? "success" : "failed");

        alert('Result submitted successfully!');
      
        setSelectedFile(null);
        setSelectedResult('');
        setPreviewUrl(null);
      }
    } catch (error) {
      console.error("Error creating market place:", error);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-lg mx-auto bg-white rounded-lg shadow-md overflow-hidden">
        <div className="bg-blue-600 px-4 py-5 sm:px-6">
          <h1 className="text-xl font-bold text-white">Submit Your Result</h1>
          <p className="text-white">{params.address}</p>
        </div>
        
        <form onSubmit={handleSubmit} className="px-4 py-5 sm:p-6">
          <div className="mb-6">
            <p htmlFor="marketTitle" className="block text-xl font-medium text-gray-700 mb-1">
              {marketData?.length && marketData[0]?.title}
            </p>
          </div>
          
          <div className="mb-6">
            <label htmlFor="resultPhoto" className="block text-sm font-medium text-gray-700 mb-1">
              Upload Photo of Your Result
            </label>
            <div className={`mt-1 border-2 border-dashed rounded-md px-6 pt-5 pb-6 flex justify-center ${
              errors.file ? 'border-red-500' : 'border-gray-300'
            }`}>
              <div className="space-y-1 text-center">
                {previewUrl ? (
                  <div className="mb-3">
                    <img 
                      src={previewUrl} 
                      alt="Preview" 
                      className="mx-auto h-32 w-auto object-cover rounded-md"
                    />
                  </div>
                ) : (
                  <svg
                    className="mx-auto h-12 w-12 text-gray-400"
                    stroke="currentColor"
                    fill="none"
                    viewBox="0 0 48 48"
                    aria-hidden="true"
                  >
                    <path
                      d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
                      strokeWidth={2}
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                )}
                
                <div className="flex text-sm text-gray-600">
                  <label
                    htmlFor="resultPhoto"
                    className="relative cursor-pointer bg-white rounded-md font-medium text-blue-600 hover:text-blue-500 focus-within:outline-none"
                  >
                    <span>Upload a file</span>
                    <input
                      id="resultPhoto"
                      name="resultPhoto"
                      type="file"
                      className="sr-only"
                      accept="image/*"
                      onChange={handleFileChange}
                    />
                  </label>
                  <p className="pl-1">or drag and drop</p>
                </div>
                <p className="text-xs text-gray-500">PNG, JPG, GIF up to 10MB</p>
              </div>
            </div>
            {errors.file && (
              <p className="mt-1 text-sm text-red-500">{errors.file}</p>
            )}
          </div>
          
          <div className="mb-6">
            <label htmlFor="result" className="block text-sm font-medium text-gray-700 mb-1">
              Select Your Result
            </label>
            <select
              id="result"
              className={`w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 ${
                errors.result ? 'border-red-500' : 'border-gray-300'
              }`}
              value={selectedResult}
              onChange={(e) => setSelectedResult(e.target.value)}
            >
              <option value="">-- Select a result --</option>
              <option value={0}>A</option>
              <option value={1}>B</option>
              <option value={2}>C</option>
              <option value={3}>D</option>
            </select>
            {errors.result && (
              <p className="mt-1 text-sm text-red-500">{errors.result}</p>
            )}
          </div>
          
          <div className="pt-4">
            <button
              type="submit"
              className="w-full px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Submit Result
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default SubmitResultPage;
